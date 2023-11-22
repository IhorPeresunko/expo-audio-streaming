import * as ExpoAudioStreamingModule from "expo-audio-streaming";
import { useState, useCallback, useEffect } from "react";

export const usePlayer = () => {
  const [playing, setPlaying] = useState(false);

  const play = useCallback(() => {
    ExpoAudioStreamingModule.play();
    setPlaying(true);
  }, [setPlaying]);

  const pause = useCallback(() => {
    ExpoAudioStreamingModule.pause();
    setPlaying(false);
  }, [setPlaying]);

  const onBufferEmpty = useCallback(() => {
    setPlaying(false);
  }, [setPlaying]);

  const onBufferPlayed = useCallback(
    (event: ExpoAudioStreamingModule.Types.BufferPlayedEvent) => {
      return event;
    },
    []
  );

  const addToBuffer = useCallback((base64: string) => {
    ExpoAudioStreamingModule.addToQueue(base64);
  }, []);

  useEffect(() => {
    const onBufferEmptyListener =
      ExpoAudioStreamingModule.addOnBufferEmptyListener(onBufferEmpty);
    const onBufferPlayedListener =
      ExpoAudioStreamingModule.addOnBufferPlayedListener(onBufferPlayed);
    return () => {
      onBufferEmptyListener.remove();
      onBufferPlayedListener.remove();
    };
  }, [onBufferEmpty, onBufferPlayed]);

  useEffect(() => {
    ExpoAudioStreamingModule.init();
  }, []);

  return {
    play,
    pause,
    addToBuffer,

    playing,
  };
};
