//
//  Live.swift
//  RealtimeMidiTransforming
//
//  Created by Thom Jordan on 6/13/20.
//  Copyright © 2020 Thom Jordan. All rights reserved.
//


import Combine
import ComposableArchitecture
import MidiPlex

extension MidimapClient {
  static let live = MidimapClient(
    create: { id in
        .run { subscriber in
            let midimapManager = MidimapManager(
                manager: MidiCenter.shared,
                handler: { msg in subscriber.send(.midimapIncoming(msg)) }
            )
            guard midimapManager.isMidiMappingAvailable else {
                subscriber.send(completion: .failure(.notAvailable))
                return AnyCancellable {}
            }
            midimapManagers[id] = midimapManager
            return AnyCancellable { midimapManagers[id] = nil }
        }
    },
    startIncomingMidi: { id in
      .fireAndForget { midimapManagers[id]?.startMidiMapping() }
    },
    stopIncomingMidi: { id in
      .fireAndForget { midimapManagers[id]?.stopMidiMapping() }
    })
}

typealias MidiNodeMessageHandler = (MidiNodeMessage) -> Void

final class MidimapManager {
  init(manager: MidiCenter, handler: @escaping MidiNodeMessageHandler) {
    self.manager = manager
    self.handler = handler
  }

  var manager: MidiCenter
  var handler: MidiNodeMessageHandler

  var isMidiMappingAvailable: Bool { return true }

  func startMidiMapping() {}

  func stopMidiMapping() {}
}

var midimapManagers: [AnyHashable: MidimapManager] = [:]

