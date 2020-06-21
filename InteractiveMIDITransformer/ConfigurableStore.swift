//
//  ConfigurableStore.swift
//  InteractiveMIDITransformer
//
//  Created by Thom Jordan on 6/21/20.
//  Copyright © 2020 Thom Jordan. All rights reserved.
//

import ComposableArchitecture


public struct ConfigurableStore<State, Action> {
    var store: Store<State, Action>
    
    init(store: Store<State, Action>) {
        self.store = store
    }
    
    public init<Environment>(
        initialState: State,
        reducer: Reducer<State, Action, Environment>,
        environment: Environment,
        configure: (Store<State, Action>) -> Void
    ) {
        self.init(store:
            Store(
                initialState: initialState,
                reducer: reducer,
                environment: environment
            )
        )
        configure(self.store)
    }
}


