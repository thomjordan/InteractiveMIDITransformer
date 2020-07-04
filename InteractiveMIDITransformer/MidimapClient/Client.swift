//
//  Client.swift
//  RealtimeMidiTransforming
//
//  Created by Thom Jordan on 6/13/20.
//  Copyright © 2020 Thom Jordan. All rights reserved.
//

import Combine
import ComposableArchitecture
import MidiPlex

struct MidiMappingClient {
  enum Action: Equatable {
    case incomingMidimapSourceEvent(MidiNodeMessage)
  }

  enum Error: Swift.Error, Equatable {
    case notAvailable
  }

  func create(id: AnyHashable) -> Effect<Action, Never> {
    self.create(id)
  }
    
  func destroy(id: AnyHashable) -> Effect<Never, Never> {
    self.destroy(id)
  }

  func startIncomingMidi(id: AnyHashable) -> Effect<Never, Never> {
    self.startIncomingMidi(id)
  }

  func stopIncomingMidi(id: AnyHashable) -> Effect<Never, Never> {
    self.stopIncomingMidi(id)
  }

  var create:  (AnyHashable) -> Effect<Action, Never>
  var destroy: (AnyHashable) -> Effect<Never, Never>
    
  var startIncomingMidi: (AnyHashable) -> Effect<Never, Never>
  var  stopIncomingMidi: (AnyHashable) -> Effect<Never, Never>
}

