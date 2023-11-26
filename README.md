# expo-audio-streaming

This module is designed to play dynamic audio streams and record audio streams from the microphone. It's an ideal solution for apps that require real-time audio processing and streaming capabilities.

### Disclaimers
#### Early Stage Development
Please note that this package is in its early stages of development. It has not been extensively tested across all environments and use cases. Users should integrate this package into their projects at their own risk.

#### iOS-Only Support
Currently, expo-audio-streaming supports iOS only. Future updates are planned to extend support to Android platforms. Feel free to contribute.

# API documentation

### Example Usage
Refer to the [example folder](https://github.com/IhorPeresunko/expo-audio-streaming-module/tree/main/example) to see how the player and recorder are utilized in a practical scenario. It is recommended to directly use the useRecorder and usePlayer hooks provided in the example. ([useRecorder.tsx](https://github.com/IhorPeresunko/expo-audio-streaming-module/blob/main/example/useRecorder.tsx), [usePlayer.tsx](https://github.com/IhorPeresunko/expo-audio-streaming-module/blob/main/example/usePlayer.tsx))

### Using the Player
Integrating the audio player into your application is straightforward. Here's a basic example:

```javascript
const { addToBuffer, play, pause, playing } = usePlayer();

// Use these methods to control the audio player
```

### Using the Recorder
Similarly, incorporating the audio recorder is just as simple. Here's a quick guide:

```javascript
const { start, stop, recording, buffer } = useRecorder({
  onNewBuffer: (event) => event.buffer,
});

// 'buffer' will be the base64 representation of your audio stream
```

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please use this command:
```
npx expo install expo-audio-streaming
```

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install expo-audio-streaming
```

### Configure for iOS

Run `npx pod-install` after installing the npm package.


### Configure for Android



# Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide]( https://github.com/expo/expo#contributing).
