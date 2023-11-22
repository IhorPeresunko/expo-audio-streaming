import ExpoModulesCore
import Foundation
import AVFoundation

let EMPTY_BUFFER_EVENT = "onBufferEmpty"
let BUFFER_PLAYED_EVENT = "onBufferPlayed"

class AudioPlayer {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: AVAudioChannelCount(1), interleaved: true)
  private let outputFormat: AVAudioFormat
  
  private var buffersInQueue = 0
  
  var onBufferFinished: (() -> Void)?
  var onBufferPlayed: ((Int) -> Void)?

  init() {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playback, mode: .default)
      try audioSession.setActive(true)
    
    } catch {
      print("Error in initializing AudioPlayer: \(error)")
    }
    
    outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)

    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: outputFormat)
  }

  func startEngine() -> Void {
    do {
      try engine.start()
    } catch {
      print("Error starting the audio engine: \(error)")
    }
  }

  func addToBuffer(buffer: AVAudioPCMBuffer) {
    guard buffer.format.isEqual(outputFormat) else {
      print("no equal \(buffer.format) \(String(describing: outputFormat))")
      return
    }
    
    self.buffersInQueue += 1

    player.scheduleBuffer(buffer) {
      DispatchQueue.main.async {
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
    player.play()
  }
  
  func pause() {
    player.pause()
  }
  
  func isPlaying() -> Bool {
    return player.isPlaying
  }
}

public class ExpoAudioStreamingModule: Module {
  private let audioPlayer = AudioPlayer()

  public func definition() -> ModuleDefinition {
    Name("ExpoAudioStreaming")
      
    Function("init") {
      self.audioPlayer.onBufferPlayed = self.onBufferPlayed
      self.audioPlayer.onBufferFinished = self.onBufferFinished
      self.audioPlayer.startEngine()
    }

    Function("play") {
      self.audioPlayer.play()
    }

    Function("pause") {
      self.audioPlayer.pause()
    }
    
    Events(BUFFER_PLAYED_EVENT, EMPTY_BUFFER_EVENT)

    Function("addToQueue") { (chunk: String) in
      guard let audioBuffer = self.audioPlayer.decodeAudioData(chunk) else {
        print("failed auido buffer")
        return
      }

      self.audioPlayer.addToBuffer(buffer: audioBuffer)
    }
  }
  
  @objc
  private func onBufferPlayed(buffersInQueue: Int) {
    sendEvent(BUFFER_PLAYED_EVENT, [
      "buffersInQueue": buffersInQueue
    ])
  }
  
  @objc
  private func onBufferFinished() {
    sendEvent(EMPTY_BUFFER_EVENT)
  }
}
