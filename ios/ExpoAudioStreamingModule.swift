import ExpoModulesCore
import Foundation
import AVFoundation

let PLAYER_EMPTY_BUFFER_EVENT = "onBufferEmptyPlayer"
let PLAYER_BUFFER_PLAYED_EVENT = "onBufferPlayedPlayer"
let RECORDER_NEW_BUFFER_EVENT = "onNewBufferRecorder"

struct PlayerConfiguration {
  let sampleRate: Double
  let channels: Int
}

struct RecorderConfiguration {
  let outputSampleRate: Double
}

class AudioPlayer {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private let inputFormat: AVAudioFormat!
  private let outputFormat: AVAudioFormat
  
  private var buffersInQueue = 0
  
  var onBufferFinished: (() -> Void)?
  var onBufferPlayed: ((Int) -> Void)?

  init(config: PlayerConfiguration) {
    inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: config.sampleRate, channels: AVAudioChannelCount(config.channels), interleaved: true)
    outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)

    engine.attach(player)
  }

  func addToBuffer(buffer: AVAudioPCMBuffer) {
    guard buffer.format.isEqual(outputFormat) else {
      print("no equal \(buffer.format) \(String(describing: outputFormat))")
      return
    }
    
    self.buffersInQueue += 1

    player.scheduleBuffer(buffer) {
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }

        self.buffersInQueue -= 1
        self.onBufferPlayed?(self.buffersInQueue)
        
        if self.buffersInQueue == 0 {
          self.onBufferFinished?()
        }
      }
    }
  }

  func decodeAudioData(_ base64String: String) -> AVAudioPCMBuffer? {
    guard let data = Data(base64Encoded: base64String) else {
      print("Error decoding base64 data")
      return nil
    }

    guard let inputFormat = inputFormat else {
      print("Error: Audio format is nil")
      return nil
    }

    let frameCount = UInt32(data.count) / inputFormat.streamDescription.pointee.mBytesPerFrame
    guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCount) else {
      print("Error creating AVAudioPCMBuffer")
      return nil
    }
    
    inputBuffer.frameLength = frameCount
    data.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) in
      if let memory = bufferPointer.baseAddress?.assumingMemoryBound(to: Int16.self) {
        inputBuffer.int16ChannelData?.pointee.update(from: memory, count: Int(frameCount))
      }
    }
    
    guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
      print("Error creating audio converter")
      return nil
    }
    
    let converterFrameCapacity = AVAudioFrameCount(outputFormat.sampleRate / inputFormat.sampleRate * Double(inputBuffer.frameCapacity))
    guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: converterFrameCapacity) else {
       print("Error creating converted buffer")
       return nil
     }
     convertedBuffer.frameLength = convertedBuffer.frameCapacity
    
    var error: NSError?
    let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
      outStatus.pointee = .haveData
      return inputBuffer
    }
    converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

    if let error = error {
      print("Error during conversion: \(error)")
      return nil
    }
      
    return convertedBuffer
  }
  
  func play() {
    let audioSession = AVAudioSession.sharedInstance()
    try! audioSession.setCategory(.playback, mode: .default)
    try! audioSession.setActive(true)
    
    engine.connect(player, to: engine.mainMixerNode, format: outputFormat)
    
    try! engine.start()
    
    player.play()
  }
  
  func pause() {
    player.pause()
    
    try! AVAudioSession.sharedInstance().setActive(false)
  }
  
  func isPlaying() -> Bool {
    return player.isPlaying
  }
}

class AudioRecorder {
  private let engine = AVAudioEngine()
  private var isRecording = false
  
  private var outputSampleRate: Double
  private var outputFormat: AVAudioFormat

  var onNewBuffer: ((String) -> Void)?

  init(config: RecorderConfiguration) {
    self.outputSampleRate = config.outputSampleRate
    self.outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: outputSampleRate, channels: 1, interleaved: true)!
  }

  func start() {
    guard !isRecording else { return }
    
    let audioSession = AVAudioSession.sharedInstance()
    try! audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers, .allowBluetooth, .allowAirPlay])
    try! audioSession.setActive(true)

    let inputFormat = engine.inputNode.inputFormat(forBus: 0)
    
    engine.inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] (buffer, _) in
      guard let self = self else { return }
      
      if (inputFormat.sampleRate != self.outputFormat.sampleRate) {
        if let outputBuffer = self.convertSampleRate(inputBuffer: buffer) {
          self.processBuffer(outputBuffer)
        }
      } else {
        self.processBuffer(buffer)
      }
    }

    try! engine.start()
    isRecording = true
  }
  
  func convertSampleRate(inputBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
    let outputFrameCapacity = AVAudioFrameCount(
      round(Double(inputBuffer.frameLength) * (outputFormat.sampleRate / inputBuffer.format.sampleRate))
    )

    guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCapacity) else { return nil }
    guard let converter = AVAudioConverter(from: inputBuffer.format, to: outputFormat) else { return nil }

    converter.convert(to: outputBuffer, error: nil) { packetCount, status in
      status.pointee = .haveData
      return inputBuffer
    }

    return outputBuffer
  }

  private func processBuffer(_ buffer: AVAudioPCMBuffer) {
    let audioBuffer = buffer.audioBufferList.pointee.mBuffers

    let audioDataSize = Int(audioBuffer.mDataByteSize)
    let audioData = audioBuffer.mData
    
    if let safeAudioData = audioData {
      let data = Data(bytes: safeAudioData, count: audioDataSize)

      let base64String = data.base64EncodedString()

      DispatchQueue.main.async {
        self.onNewBuffer?(base64String)
      }
    }
  }

  func stop() {
    guard isRecording else { return }

    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
    do {
      try AVAudioSession.sharedInstance().setActive(false)
    } catch {
      print("Error deactivating audio session: \(error)")
    }
    
    isRecording = false
  }
}

public class ExpoAudioStreamingModule: Module {
  private var audioPlayer: AudioPlayer!
  private var audioRecorder: AudioRecorder!

  public func definition() -> ModuleDefinition {
    Name("ExpoAudioStreaming")

    Events(PLAYER_BUFFER_PLAYED_EVENT, PLAYER_EMPTY_BUFFER_EVENT, RECORDER_NEW_BUFFER_EVENT)
    
    /* ------- PLAYER ------- */
    Function("initPlayer") { (sampleRate: Double, channels: Int) in
      let config = PlayerConfiguration(sampleRate: sampleRate, channels: channels)
      
      self.audioPlayer = AudioPlayer(config: config)
      self.audioPlayer.onBufferPlayed = self.onPlayerBufferPlayed
      self.audioPlayer.onBufferFinished = self.onPlayerBufferFinished
    }

    Function("playPlayer") {
      self.audioPlayer.play()
    }

    Function("pausePlayer") {
      self.audioPlayer.pause()
    }    

    Function("addToQueuePlayer") { (chunk: String) in
      guard let audioBuffer = self.audioPlayer.decodeAudioData(chunk) else {
        print("failed auido buffer")
        return
      }

      self.audioPlayer.addToBuffer(buffer: audioBuffer)
    }
    
    /* ------- RECORDER ------- */
    Function("initRecorder") { (outputSampleRate: Double) in
      let config = RecorderConfiguration(outputSampleRate: outputSampleRate)

      self.audioRecorder = AudioRecorder(config: config)
      self.audioRecorder.onNewBuffer = self.onRecorderBuffer
    }

    AsyncFunction("startRecorder") { [weak self] (promise: Promise) in
      DispatchQueue.global(qos: .background).async {
        self?.audioRecorder.start()
        
        DispatchQueue.main.async {
          promise.resolve()
        }
      }
    }

    Function("stopRecorder") {
      self.audioRecorder.stop()
    }
  }
  
  private func onPlayerBufferPlayed(buffersInQueue: Int) {
    sendEvent(PLAYER_BUFFER_PLAYED_EVENT, [
      "buffersInQueue": buffersInQueue
    ])
  }
  
  private func onPlayerBufferFinished() {
    sendEvent(PLAYER_EMPTY_BUFFER_EVENT)
  }
  
  private func onRecorderBuffer(base64: String) {
    sendEvent(RECORDER_NEW_BUFFER_EVENT, [
      "buffer": base64
    ])
  }
}
