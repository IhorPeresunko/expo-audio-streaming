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

export function addOnBufferEmptyListener(
  listener: (event) => void
): Subscription {
  return addListener("onBufferEmpty", listener);
}

export function addOnBufferPlayedListener(
  listener: (event) => Types.BufferPlayedEvent
): Subscription {
  return addListener("onBufferPlayed", listener);
}

export function play(): void {
  ExpoAudioStreamingModule.play();
}

export function pause(): void {
  ExpoAudioStreamingModule.pause();
}

export function addToQueue(base64: string) {
  ExpoAudioStreamingModule.addToQueue(base64);
}

export function init() {
  ExpoAudioStreamingModule.init();
}

export * as Types from "./ExpoAudioStreamingModule.types";
