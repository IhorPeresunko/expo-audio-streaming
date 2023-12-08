import ExpoModulesCore
import Foundation
import AVFoundation

let PLAYER_EMPTY_BUFFER_EVENT = "onBufferEmptyPlayer"
let PLAYER_BUFFER_PLAYED_EVENT = "onBufferPlayedPlayer"
let RECORDER_NEW_BUFFER_EVENT = "onNewBufferRecorder"

struct PlayerConfiguration {
  let sampleRate: Double
  let channels: Int
  let engine: AVAudioEngine
}

struct RecorderConfiguration {
  let outputSampleRate: Double
  let outputBufferSize: AVAudioFrameCount
  let outputChannels: AVAudioChannelCount
  let engine: AVAudioEngine
}

class AudioEngineManager {
  let engine = AVAudioEngine()
  let recorder: AudioRecorder
  let player: AudioPlayer

  init(recorderSampleRate: Double, recorderBufferSize: AVAudioFrameCount, recorderChannels: AVAudioChannelCount, playerSampleRate: Double, playerChannels: Int) {
    let recorderConfig = RecorderConfiguration(
      outputSampleRate: recorderSampleRate,
      outputBufferSize: recorderBufferSize,
      outputChannels: recorderChannels,
      engine: engine
    )
    
    let playerConfig = PlayerConfiguration(
      sampleRate: playerSampleRate,
      channels: playerChannels,
      engine: engine
    )

    self.recorder = AudioRecorder(config: recorderConfig)
    self.player = AudioPlayer(config: playerConfig)
  }

  func startAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowAirPlay, .defaultToSpeaker, .interruptSpokenAudioAndMixWithOthers])
      try audioSession.setActive(true)
      
      NSLog("[ExpoAudioStreaming] Audio Session Started")
    } catch {
      NSLog("[ExpoAudioStreaming] Failed to set audio session category: \(error)")
    }
  }
  
  func stopAudioSession() {
    try! AVAudioSession.sharedInstance().setActive(false)
  }
  
  func startEngine() {
    if !engine.isRunning {
      do {
        try engine.start()
        NSLog("[ExpoAudioStreaming] Engine Started")
      } catch {
        NSLog("[ExpoAudioStreaming] Could not start audio engine: \(error)")
      }
    }
  }

  func stopEngine() {
    engine.stop()
  }
  
  func playerStart() {
    self.startEngine()
    self.player.play()
  }
  
  func playerStop() {
    self.player.pause()
  }
  
  func recordStart() {
    self.startEngine()
    self.recorder.start()
  }
  
  func recordStop() {
    if engine.isRunning {
      engine.stop()
    }
    self.recorder.stop()
  }
}


class AudioPlayer {
  private let engine: AVAudioEngine
  private let player = AVAudioPlayerNode()
  private let inputFormat: AVAudioFormat!
  private let outputFormat: AVAudioFormat
  
  private var buffersInQueue = 0
  
  var onBufferFinished: (() -> Void)?
  var onBufferPlayed: ((Int) -> Void)?

  init(config: PlayerConfiguration) {
    self.engine = config.engine

    inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: config.sampleRate, channels: AVAudioChannelCount(config.channels), interleaved: true)
    outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)

    if !engine.attachedNodes.contains(player) {
      engine.attach(player)
    }
    engine.connect(player, to: engine.mainMixerNode, format: nil)
  }

  func addToBuffer(buffer: AVAudioPCMBuffer) {
    guard buffer.format.isEqual(outputFormat) else {
      NSLog("[ExpoAudioStreaming] no equal \(buffer.format) \(String(describing: outputFormat))")
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
      NSLog("[ExpoAudioStreaming] Error decoding base64 data")
      return nil
    }

    guard let inputFormat = inputFormat else {
      NSLog("[ExpoAudioStreaming] Error: Audio format is nil")
      return nil
    }

    let frameCount = UInt32(data.count) / inputFormat.streamDescription.pointee.mBytesPerFrame
    guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCount) else {
      NSLog("[ExpoAudioStreaming] Error creating AVAudioPCMBuffer")
      return nil
    }
    
    inputBuffer.frameLength = frameCount
    data.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) in
      if let memory = bufferPointer.baseAddress?.assumingMemoryBound(to: Int16.self) {
        inputBuffer.int16ChannelData?.pointee.update(from: memory, count: Int(frameCount))
      }
    }
    
    guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
      NSLog("[ExpoAudioStreaming] Error creating audio converter")
      return nil
    }
    
    let converterFrameCapacity = AVAudioFrameCount(outputFormat.sampleRate / inputFormat.sampleRate * Double(inputBuffer.frameCapacity))
    guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: converterFrameCapacity) else {
       NSLog("[ExpoAudioStreaming] Error creating converted buffer")
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
      NSLog("[ExpoAudioStreaming] Error during conversion: \(error)")
      return nil
    }
      
    return convertedBuffer
  }
  
  func play() {
    player.play()
  }
  
  func pause() {
    player.pause()
  }
  
  func isPlaying() -> Bool {
    return player.isPlaying
  }
  
  func reset() {
    player.stop()
    player.reset()
    buffersInQueue = 0
  }
}

class AudioRecorder {
  private let engine: AVAudioEngine
  private var isRecording = false
  
  private var outputSampleRate: Double
  private var outputFormat: AVAudioFormat
  private let inputNode: AVAudioInputNode
  private var bufferSize: AVAudioFrameCount
  private var channels: AVAudioChannelCount

  var onNewBuffer: ((String) -> Void)?

  init(config: RecorderConfiguration) {
    self.engine = config.engine
    self.outputSampleRate = config.outputSampleRate
    self.bufferSize = config.outputBufferSize
    self.channels = config.outputChannels

    self.outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: outputSampleRate, channels: channels, interleaved: true)!
    
    self.inputNode = engine.inputNode
  }

  func start() {
    guard !isRecording else { return }

    let inputFormat = inputNode.inputFormat(forBus: 0)

    NSLog("[ExpoAudioStreaming] input: \(inputFormat). output: \(self.outputFormat)")
    
    inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] (buffer, _) in
      guard let self = self else { return }
    
      if let outputBuffer = self.convertSampleRate(inputBuffer: buffer) {
        self.processBuffer(outputBuffer)
      } else {
        NSLog("[ExpoAudioStreaming] Failed to convert recorder buffer to output format")
      }
    }

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
    inputNode.removeTap(onBus: 0)
    isRecording = false
  }
}

public class ExpoAudioStreamingModule: Module {
  private var audioManager: AudioEngineManager!
  private var audioPlayer: AudioPlayer!
  private var audioRecorder: AudioRecorder!

  public func definition() -> ModuleDefinition {
    Name("ExpoAudioStreaming")

    Events(PLAYER_BUFFER_PLAYED_EVENT, PLAYER_EMPTY_BUFFER_EVENT, RECORDER_NEW_BUFFER_EVENT)
    
    Function("init") { (recorderSampleRate: Double, recorderBufferSize: AVAudioFrameCount, recorderChannels: AVAudioChannelCount, playerSampleRate: Double, playerChannels: Int) in
      self.audioManager = AudioEngineManager(
        recorderSampleRate: recorderSampleRate,
        recorderBufferSize: recorderBufferSize,
        recorderChannels: recorderChannels,
        playerSampleRate: playerSampleRate,
        playerChannels: playerChannels
      )
      self.audioPlayer = audioManager.player
      self.audioRecorder = audioManager.recorder

      self.audioRecorder.onNewBuffer = self.onRecorderBuffer
      self.audioPlayer.onBufferPlayed = self.onPlayerBufferPlayed
      self.audioPlayer.onBufferFinished = self.onPlayerBufferFinished
      
      self.audioManager.startAudioSession()
    }
    
    Function("destroy") {
      self.audioManager.stopAudioSession()
    }
    
    /* ------- PLAYER ------- */
    Function("playPlayer") {
      self.audioManager.playerStart()
    }

    Function("pausePlayer") {
      self.audioManager.playerStop()
    }

    Function("addToQueuePlayer") { (chunk: String) in
      guard let audioBuffer = self.audioPlayer.decodeAudioData(chunk) else {
        NSLog("[ExpoAudioStreaming] failed auido buffer")
        return
      }

      self.audioPlayer.addToBuffer(buffer: audioBuffer)
    }
    
    Function("resetBuffer") {
      self.audioPlayer.reset()
    }
    
    /* ------- RECORDER ------- */
    Function("startRecorder") {
      self.audioManager.recordStart()
    }

    Function("stopRecorder") {
      self.audioManager.recordStop()
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
