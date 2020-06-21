//
//  MultistateTransport.swift
//  RealtimeMidiTransforming
//
//  Created by Thom Jordan on 6/7/20.
//  Copyright © 2020 Thom Jordan. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import AppKit

extension NSView {
    func updateView() {
        DispatchQueue.main.async { [weak self] in
            self?.needsDisplay = true
        }
    }
    func localizePoint(_ sender: NSEvent) -> NSPoint {
        let eventLocation = sender.locationInWindow
        return self.convert(eventLocation, from: nil)
    }
}

final class NSTransportButton: NSView {
    
    let transportButton: TransportButton
    var state: Int = 1
    
    private let stopButtonRegion: NSRect = NSMakeRect(0, 0, 44, 33)
    private let playButtonRegion: NSRect = NSMakeRect(45, 0, 44, 33)
    
    init(initialState: Int, transportButton: TransportButton) {
        self.transportButton = transportButton
        self.state = initialState
        super.init(frame: CGRect(x: 0, y: 0, width: 89, height: 33))
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override public func draw(_ rect: CGRect) {
        MultistateTransportStyleKit_macOS.drawTransportButton(transportState: CGFloat(state))
    }
    
    private func stopButtonClicked(_ event: NSEvent) -> Bool {
        if stopButtonRegion.contains( localizePoint(event) ) { return true }
        return false
    }
    private func playButtonClicked(_ event: NSEvent) -> Bool {
        if playButtonRegion.contains( localizePoint(event) ) { return true }
        return false
    }

    public override func mouseDown(with event: NSEvent) {
        if playButtonClicked(event) { self.transportButton.playAction() }
        else if stopButtonClicked(event) { self.transportButton.stopAction() }
        updateView()
    }

    public override func mouseUp(with event: NSEvent) {
        self.transportButton.liftAction()
        updateView()
    }
}


struct TransportButtonMac: NSViewRepresentable {
    var state: Int
    let transportButton: TransportButton
    
    func makeNSView(context: Context) -> NSTransportButton {
        let button = NSTransportButton(initialState: self.state, transportButton: self.transportButton)
        return button
    }
    func updateNSView(_ button: NSTransportButton, context: Context) {
        button.state = self.state
        button.needsDisplay = true
    }
}

public struct TransportButton: View {
    public init(playAction: @escaping () -> Void, stopAction: @escaping () -> Void, liftAction: @escaping () -> Void, state: Int) {
        self.playAction = playAction
        self.stopAction = stopAction
        self.liftAction = liftAction
        self.state = state
    }
    
    var playAction: () -> Void
    var stopAction: () -> Void
    var liftAction:  () -> Void 
    var state: Int
    
    public var body: some View {
        return TransportButtonMac(state: self.state, transportButton: self)
    }
}
