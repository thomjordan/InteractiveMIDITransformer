//
//  RealtimeMidiProcessor.swift
//  RealtimeMidiTransforming
//
//  Created by Thom Jordan on 5/13/20.
//  Copyright © 2020 Thom Jordan. All rights reserved.
//

import ComposableArchitecture
import SwiftUI
import Combine
import MidiPlex

// ******************************************************

struct ControlsState: Equatable {
    var cc1value: Double = 0.0
    var cc2value: Double = 0.0
}

enum ControlsAction: Equatable {
  case slider1Changed(Double)
  case slider2Changed(Double)
}

struct ControlsEnvironment {}

// ******************************************************

struct TransportState: Equatable {
    enum Status : Int {
        case stopClicked  = 0
        case stoppedState = 1
        case playClicked  = 2
        case playingState  = 3
        case restartPlay  = 4
        case stoppingPlay = 5
        var description: String { return String(describing: self) }
    }
    enum Mode {
        case playing
        case stopped
        var description: String { return String(describing: self) }
    }
    enum ActionStatus {
        case pressingPlay
        case pressingStop
        case nonaction
    }
    var status       : Status       = .stoppedState
    var mode         : Mode         = .stopped
    var actionStatus : ActionStatus = .nonaction
}

enum TransportAction: Equatable {
    case playButtonEngaged
    case stopButtonEngaged
    case buttonReleased
    case play
    case stop
}

struct TransportEnvironment {}

// ******************************************************

struct AppState: Equatable {
    var controls  = ControlsState()
    var transport = TransportState()
}

enum AppAction: Equatable {
    case controls(ControlsAction)
    case transport(TransportAction)
    case midiMappingClient(MidiMappingClient.Action)
    case onAppear
    case onDisappear
}

struct AppEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var midiMappingClient: MidiMappingClient
    
    static let live = AppEnvironment(
      mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
      midiMappingClient: .live
    )
}

// ******************************************************

let controlsReducer = Reducer<ControlsState, ControlsAction, ControlsEnvironment> { state, action, _ in
  switch action {
  case let .slider1Changed(value):
    state.cc1value = value
    return .none
  case let .slider2Changed(value):
    state.cc2value = value
    return .none
  }
}

let transportReducer = Reducer<TransportState, TransportAction, TransportEnvironment> { state, action, _ in
    switch action {
    case .playButtonEngaged:
        if state.status == .stoppedState {
            state.actionStatus = .pressingPlay
            state.status = .playClicked
        }
        else if state.status == .playingState {
            state.actionStatus = .pressingPlay
            state.status = .restartPlay
        }
        return .none
    case .stopButtonEngaged:
        if state.status == .stoppedState {
            state.actionStatus = .pressingStop
            state.status = .stopClicked
        }
        else if state.status == .playingState {
            state.actionStatus = .pressingStop
            state.status = .stoppingPlay
        }
        return .none
    case .buttonReleased:
        if state.actionStatus == .pressingPlay {
            return Effect(value: TransportAction.play).eraseToEffect()
        }
        else if state.actionStatus == .pressingStop {
            return Effect(value: TransportAction.stop).eraseToEffect()
        }
        return .none
    case .play:
        state.mode  = .playing
        state.status = .playingState
        state.actionStatus = .nonaction
        return .none
    case .stop:
        state.mode  = .stopped
        state.status = .stoppedState
        state.actionStatus = .nonaction
        return .none
    }
}

let appReducer_ = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    struct MidiMappingClientId: Hashable {}
    
    switch action {
        
    case .controls:
        return .none
        
    case .transport:
        return .none
        
    case .onAppear:
        return environment.midiMappingClient.create(id: MidiMappingClientId())
            //.receive(on: environment.mainQueue)
            .map(AppAction.midiMappingClient)
            //.eraseToEffect()

    case .onDisappear:
        return environment.midiMappingClient.destroy(id: MidiMappingClientId())
            .fireAndForget()
        
    case let .midiMappingClient(.incomingMidimapSourceEvent(msg)):
        var result: Effect<AppAction, Never>?
        //DispatchQueue.main.async {
        print("ccnum: \(msg.ccnum), value: \(msg.ccval)")
        guard msg.messageType == .controlChange else { return .none }
        //print("ccnum: \(msg.ccnum), value: \(msg.ccval)")
        switch (msg.data1, msg.data2) {
        case (0, _):    result = Effect(value: AppAction.controls(.slider1Changed(Double(msg.data2))))
        case (1, _):    result = Effect(value: AppAction.controls(.slider2Changed(Double(msg.data2))))
        case (41, 127): result = Effect(value: AppAction.transport(.playButtonEngaged))
        case (41,   0): result = Effect(value: AppAction.transport(.buttonReleased))
        case (42, 127): result = Effect(value: AppAction.transport(.stopButtonEngaged))
        case (42,   0): result = Effect(value: AppAction.transport(.buttonReleased))
        default: break
        }
        //}
        return result ?? .none
//            .receive(on: environment.mainQueue)
//            .eraseToEffect() ?? .none
        
//h
    }
}
.combined( with: controlsReducer.pullback( state: \AppState.controls, action: /AppAction.controls, environment: { _ in ControlsEnvironment() } ) )
.combined( with: transportReducer.pullback( state: \AppState.transport, action: /AppAction.transport, environment: { _ in TransportEnvironment() } ) )


let appReducer = Reducer<AppState, AppAction, AppEnvironment>
.combine(
  controlsReducer.pullback(
    state: \AppState.controls,
    action: /AppAction.controls,
    environment: { _ in ControlsEnvironment() }
  ),
  transportReducer.pullback(
    state: \AppState.transport,
    action: /AppAction.transport,
    environment: { _ in TransportEnvironment() }
  )
)

// ******************************************************

let sliderSize: CGFloat = 216

struct ControlsView: View {
  let store: Store<ControlsState, ControlsAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        HStack {
          Slider(
            value: viewStore.binding(
              get: { $0.cc1value }, send: ControlsAction.slider1Changed),  in: 0...127
          ).frame(width: sliderSize, height: 20, alignment: .center)
          Text("\(viewStore.cc1value, specifier: "%.0f")").frame(width: 28, height: 20, alignment: .center)
        }
        HStack {
          Slider(
            value: viewStore.binding(
              get: { $0.cc2value }, send: ControlsAction.slider2Changed),  in: 0...127
          ).frame(width: sliderSize, height: 20, alignment: .center)
          Text("\(viewStore.cc2value, specifier: "%.0f")").frame(width: 28, height: 20, alignment: .center)
        }
      }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
    }
  }
}

struct TransportView: View {
    let store: Store<TransportState, TransportAction>

    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                TransportButton(
                    playAction: { viewStore.send(TransportAction.playButtonEngaged) },
                    stopAction: { viewStore.send(TransportAction.stopButtonEngaged) },
                    liftAction: { viewStore.send(TransportAction.buttonReleased)    },
                    state: viewStore.status.rawValue)
                .frame(width: 89, height: 33, alignment: .center)
                Text(viewStore.mode.description).frame(width: 89, height: 33, alignment: .center)
                Text(viewStore.status.description).frame(width: 89, height: 33, alignment: .center)
            }
        }
    }
}

struct AppView: View {
    let store: Store<AppState, AppAction>
    var body: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                ControlsView(store: self.store.scope(state: { $0.controls }, action: AppAction.controls) )
                TransportView(store: self.store.scope(state: { $0.transport }, action: AppAction.transport) )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

// ******************************************************

let startMidi: (Store<AppState, AppAction>) -> Void = { store in
    onMidiReceive { msg in
        DispatchQueue.main.async {
            guard msg.messageType == .controlChange else { return }
            print("cc: \(msg.ccnum), value: \(msg.ccval)")
            switch (msg.data1, msg.data2) {
            case (0, _):    store.send(AppAction.controls(.slider1Changed(Double(msg.data2))))
            case (1, _):    store.send(AppAction.controls(.slider2Changed(Double(msg.data2))))
            case (41, 127): store.send(AppAction.transport(.playButtonEngaged))
            case (41,   0): store.send(AppAction.transport(.buttonReleased))
            case (42, 127): store.send(AppAction.transport(.stopButtonEngaged))
            case (42,   0): store.send(AppAction.transport(.buttonReleased))
            default: break
            }
        }
    }
}

let appStore = ConfigurableStore(
    initialState: AppState(),
    reducer: appReducer,
    environment: AppEnvironment.live
) { `self` in startMidi(self) }.store


let appStore_ = Store(
    initialState: AppState(),
    reducer: appReducer_,
    environment: AppEnvironment.live
)


public struct TheView {
  public static var contents: some View =
    AppView( store: appStore )
}


