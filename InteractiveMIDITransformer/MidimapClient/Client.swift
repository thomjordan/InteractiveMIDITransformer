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

struct MidimapClient {
  enum Action: Equatable {
    case midimapIncoming(MidiNodeMessage)
  }

  enum Error: Swift.Error, Equatable {
    case midimapIncomingFailed(String)
    case notAvailable
  }

  func create(id: AnyHashable) -> Effect<Action, Error> {
    self.create(id)
  }

  func startIncomingMidi(id: AnyHashable) -> Effect<Never, Never> {
    self.startIncomingMidi(id)
  }

  func stopIncomingMidi(id: AnyHashable) -> Effect<Never, Never> {
    self.stopIncomingMidi(id)
  }

  var create: (AnyHashable) -> Effect<Action, Error>
  var startIncomingMidi: (AnyHashable) -> Effect<Never, Never>
  var  stopIncomingMidi: (AnyHashable) -> Effect<Never, Never>
}

