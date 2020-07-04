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

extension MidiMappingClient {
  static let live = MidiMappingClient(
    create: { id in
        .run { subscriber in
            let midiMappingManager = MidiMappingManager(
                manager: MidiCenter.shared,
                handler: { msg in
                    print("ccnum: \(msg.ccnum), value: \(msg.ccval)")
                    subscriber.send(.incomingMidimapSourceEvent(msg))
                    if msg.messageType == .controlChange {
                        print("ccnum: \(msg.ccnum), value: \(msg.ccval)")
                    }
                }
            )
            
            midiMappingManagers[id] = midiMappingManager
            midiMappingManagers[id]?.registerMidiReceiveHandler() 
            
            return AnyCancellable {
                midiMappingManagers[id]?.unregisterMidiReceiveHandler()
                midiMappingManagers[id] = nil
            }
        }
    },
    destroy: { id in
        .fireAndForget {
            midiMappingManagers[id]?.unregisterMidiReceiveHandler()
            midiMappingManagers[id] = nil
        }
    },
    // for use with a button-switch control to toggle midiMapping on and off
    startIncomingMidi: { id in
        .fireAndForget { midiMappingManagers[id]?.registerMidiReceiveHandler() }
    },
    stopIncomingMidi: { id in
      .fireAndForget { midiMappingManagers[id]?.unregisterMidiReceiveHandler() }
    })
}

typealias MidiNodeMessageHandler = (MidiNodeMessage) -> Void


final class MidiMappingManager {
    var uuid: Int?
    
  init(manager: MidiCenter, handler: @escaping MidiNodeMessageHandler) {
    self.manager = manager
    self.handler = handler
  }

  var manager: MidiCenter
  var handler: MidiNodeMessageHandler

  func registerMidiReceiveHandler() {
    self.uuid = self.manager.registerMidiReceiveHandler(handler)
  }

  func unregisterMidiReceiveHandler() {
    if let id = self.uuid {
      self.manager.unregisterMidiReceiveHandler(at: id)
    }
  }
}

var midiMappingManagers: [AnyHashable: MidiMappingManager] = [:]

