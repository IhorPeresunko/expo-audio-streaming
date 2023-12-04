import { EventEmitter, Subscription } from "expo-modules-core";
import ExpoAudioStreamingModule from "./ExpoAudioStreamingModule";
import * as Types from "./ExpoAudioStreamingModule.types";

const emitter = new EventEmitter(ExpoAudioStreamingModule);

function addListener(
  eventName: string,
  listener: (event) => void
): Subscription {
  return emitter.addListener(eventName, listener);
}

export const Player = {
  addOnBufferPlayedListener(
    listener: (event: Types.PlayerBufferPlayedEvent) => void
  ): Subscription {
    return addListener("onBufferPlayedPlayer", listener);
  },

  addOnBufferEmptyListener(listener: (event) => void): Subscription {
    return addListener("onBufferEmptyPlayer", listener);
  },

  play(): void {
    ExpoAudioStreamingModule.playPlayer();
  },

  pause(): void {
    ExpoAudioStreamingModule.pausePlayer();
  },

  addToQueue(base64: string) {
    ExpoAudioStreamingModule.addToQueuePlayer(base64);
  },

  init(config: Types.PlayerConfiguration = {}): void {
    const c: Types.PlayerConfiguration = {
      sampleRate: 44100,
      channels: 1,
      ...config,
    };

    ExpoAudioStreamingModule.initPlayer(c.sampleRate, c.channels);
  },
};

export const Recorder = {
  addOnNewBufferListener(
    listener: (event: Types.RecorderNewBufferEvent) => void
  ): Subscription {
    return addListener("onNewBufferRecorder", listener);
  },

  init(config: Types.RecorderConfiguration = {}): void {
    const c: Types.RecorderConfiguration = {
      outputSampleRate: 16000,
      ...config,
    };

    ExpoAudioStreamingModule.initRecorder(c.outputSampleRate);
  },

  start(): Promise<void> {
    return ExpoAudioStreamingModule.startRecorder();
  },

  stop(): void {
    ExpoAudioStreamingModule.stopRecorder();
  },
};

export * as Types from "./ExpoAudioStreamingModule.types";
