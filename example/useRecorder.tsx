import { Recorder, Types } from "expo-audio-streaming";
import { useState, useCallback, useEffect } from "react";

export const useRecorder = ({
  onNewBuffer,
}: {
  onNewBuffer: (event: Types.RecorderNewBufferEvent) => void;
}) => {
  const [recording, setRecording] = useState(false);
  const [buffer, setBuffer] = useState<string[]>([]);

  const start = useCallback(() => {
    Recorder.start();
    setRecording(true);
  }, [setRecording]);

  const stop = useCallback(() => {
    Recorder.stop();
    setRecording(false);
  }, [setRecording]);

  const _onNewBuffer = useCallback(
    (event: Types.RecorderNewBufferEvent) => {
      setBuffer((prev) => [...prev, event.buffer]);
      onNewBuffer(event);
    },
    [onNewBuffer, setBuffer]
  );

  useEffect(() => {
    const onNewBufferListener = Recorder.addOnNewBufferListener(_onNewBuffer);

    return () => {
      onNewBufferListener.remove();
    };
  }, [_onNewBuffer]);

  useEffect(() => {
    Recorder.init();
  }, []);

  return {
    start,
    stop,
    buffer,

    recording,
  };
};
