import { Player, Types } from "expo-audio-streaming";
import { useState, useCallback, useEffect } from "react";

export const usePlayer = () => {
  const [playing, setPlaying] = useState(false);

  const play = useCallback(() => {
    Player.play();
    setPlaying(true);
  }, [setPlaying]);

  const pause = useCallback(() => {
    Player.pause();
    setPlaying(false);
  }, [setPlaying]);

  const onBufferEmpty = useCallback(() => {
    setPlaying(false);
  }, [setPlaying]);

  const onBufferPlayed = useCallback((event: Types.PlayerBufferPlayedEvent) => {
    return event;
  }, []);

  const addToBuffer = useCallback((base64: string) => {
    Player.addToQueue(base64);
  }, []);

  useEffect(() => {
    const onBufferEmptyListener =
      Player.addOnBufferEmptyListener(onBufferEmpty);
    const onBufferPlayedListener =
      Player.addOnBufferPlayedListener(onBufferPlayed);
    return () => {
      onBufferEmptyListener.remove();
      onBufferPlayedListener.remove();
    };
  }, [onBufferEmpty, onBufferPlayed]);

  useEffect(() => {
    Player.init();
  }, []);

  return {
    play,
    pause,
    addToBuffer,

    playing,
  };
};
