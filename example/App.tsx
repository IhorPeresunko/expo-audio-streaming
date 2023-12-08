import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { AudioSession } from "expo-audio-streaming";

import { usePlayer } from "./usePlayer";
import { audio } from "./mock-stream";
import { useRecorder } from "./useRecorder";
import Spinner from "./Spinner";
import { useEffect } from "react";

export default function App() {
  const { addToBuffer, play, pause, playing, resetBuffer } = usePlayer();
  const { start, stop, recording, buffer } = useRecorder();

  useEffect(() => {
    AudioSession.init({
      playerSampleRate: 16000,
      recorderSampleRate: 16000,
      recorderBufferSize: 2048,
    });

    return () => {
      AudioSession.destroy();
    };
  }, [AudioSession]);

  const startStreamingMockData = () => {
    for (let i = 0; i < audio.length; i++) {
      setTimeout(() => {
        addToBuffer(audio[i]);
      }, 0);
    }
  };

  const startStreamingRecordingData = () => {
    for (let i = 0; i < buffer.length; i++) {
      addToBuffer(buffer[i]);
    }
  };

  return (
    <View style={styles.container}>
      <Text>Status: {playing ? "Playing" : "Not Playing"}</Text>
      {playing ? (
        <TouchableOpacity onPress={pause} style={styles.button}>
          <Text>Stop Playing</Text>
        </TouchableOpacity>
      ) : (
        <TouchableOpacity onPress={play} style={styles.button}>
          <Text>Start Playing</Text>
        </TouchableOpacity>
      )}

      <TouchableOpacity onPress={startStreamingMockData} style={styles.button}>
        <Text>Stream mock buffer to player</Text>
      </TouchableOpacity>

      <TouchableOpacity onPress={resetBuffer} style={styles.button}>
        <Text>Reset Buffer</Text>
      </TouchableOpacity>

      <Text style={styles.p}>--------</Text>

      <Text>Status: {recording ? "Recording" : "Not Recording"}</Text>
      {recording ? (
        <TouchableOpacity onPress={stop} style={styles.button}>
          <Text>Stop Recording</Text>
        </TouchableOpacity>
      ) : (
        <TouchableOpacity onPress={start} style={styles.button}>
          <Text>Start Recording</Text>
        </TouchableOpacity>
      )}
      <TouchableOpacity
        onPress={startStreamingRecordingData}
        style={styles.button}
      >
        <Text>Stream recording buffer to player</Text>
      </TouchableOpacity>

      {/* To check if im not blocking main thread */}
      <Spinner />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
  button: {
    padding: 10,
    backgroundColor: "#EBEBEB",
    borderRadius: 5,
    marginTop: 10,
  },
  p: {
    paddingVertical: 40,
  },
});
