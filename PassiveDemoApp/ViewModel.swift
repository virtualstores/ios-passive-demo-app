//
//  ViewModel.swift
//  PassiveDemoApp
//
//  Created by Hripsime on 2022-03-02.
//

import VSFoundation
import VSTT2
import Combine
import UIKit

public final class ViewModel {
    let tt2 = TT2()
    
    public var stopLoading: CurrentValueSubject<Bool?, Never> = .init(nil)
    public var showMessagePublisher: CurrentValueSubject<Void?, Never> = .init(nil)
    public var currentStore: TT2Store?
    
    public var messageTitle: String?
    public var messageDesc: String?
    
    private var analyticsMessgeCancellable: AnyCancellable?
    
    private var currentEvent: TriggerEvent?
    private var user: User?
    
    public init(with user: User) {
        let connection = ServerConnection(apiKey: "kanelbulle", serverAddress: "https://gunnis-hp-central.ih.vs-office.se", mqttAddress: nil, storeId: 0)
        tt2.initialize(with: connection.serverAddress!, apiKey: connection.apiKey!, clientId: 1) { [weak self] error in
            if error == nil {
                guard let store = self?.tt2.activeStores.first else { return }
                
                self?.currentStore = store
            
                self?.user = user
                self?.tt2.userSettings.setUser(user: user)

                self?.tt2.initiateStore(store: store) { error in
                    self?.stopLoading.send(true)
                }
            }
        }
        
        bindPublishers()
    }
    
    public func start() {
        startNavigation()
        startVisit()
    }
    
    public func getItemBy(shelfName: String) {
        tt2.position.getBy(shelfName: shelfName) { itemPosition in
            self.tt2.navigation.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                do {
                    try self.tt2.navigation.start(startPosition: itemPosition.point)
                } catch {
                    Logger.init().log(message: "GetItemByShelfName startUpdatingLocation error")
                }
            }
        }
    }
    
    public func getItemBy(barcode: String) {
        tt2.position.getBy(barcode: barcode) { (barcodePositions) in
            barcodePositions?.forEach { (position) in
                Logger(verbosity: .debug).log(message: "\(position.itemPosition!), \(position.shelfId!), \(position.rtlsOptionsId!)")
            }
        }
    }
    
    public func addCompletedTriggerEvent() {
        guard let currentEvent = self.currentEvent else { return }
        currentEvent.eventType = .appTrigger(TriggerEvent.AppTrigger(event: currentEvent.name))
        tt2.analytics.addTriggerEvent(for: currentEvent)
    }
    
    public func createCustomEvent() {
        let trigger = TriggerEvent.CoordinateTrigger(point: CGPoint(x: 5.0, y: 10.0), radius: 5)
        let event = TriggerEvent(rtlsOptionsId: "18", name: "Testing", description: "Test description", eventType: TriggerEvent.EventType.coordinateTrigger(trigger))
        self.tt2.analytics.evenManager.addEvent(event: event)
    }
    
    private func startNavigation() {
        guard let location = tt2.rtlsOption?.scanLocations?.first(where: { $0.type == .start }) else { return }
        
        do {
            //try self.tt2.navigation.compassStartNavigation(startPosition: location.point)
            try self.tt2.navigation.start(startPosition: location.point, startAngle: location.direction)
        } catch {
            Logger.init().log(message: "startUpdatingLocation error")
        }
    }
    
    private func startVisit() {
        let device = UIDevice.current
        let deviceInformation = DeviceInformation(id: device.name,
                                                  operatingSystem: device.systemName,
                                                  osVersion: device.systemVersion,
                                                  appVersion: "1.0",
                                                  deviceModel: device.modelName)
        
        guard let user = user, let age = user.age, let gender = user.gender, let userId = user.userId else { fatalError("Missing User data") }
        
        let tags: [String : String] = ["age": String(age), "gender": gender, "userId": userId]

        tt2.analytics.startVisit(deviceInformation: deviceInformation, tags: tags) { (error) in
            if error == nil {
                self.startCollectingHeatMapData()
            }
        }
    }
    
    private func startCollectingHeatMapData() {
        do {
            try tt2.analytics.startCollectingHeatMapData()
        } catch {
            Logger.init(verbosity: .debug).log(message: error.localizedDescription)
        }
    }
    
    private func bindPublishers() {
        analyticsMessgeCancellable = tt2.analytics.evenManager.messageEventPublisher
            .compactMap({ $0 })
            .sink { [weak self] event in
                self?.currentEvent = event
                self?.messageTitle = event.name
                self?.messageDesc = event.description
                self?.showMessagePublisher.send(())
            }
    }
    
    func stop() {
        tt2.navigation.stop()
        tt2.analytics.stopVisit()
        tt2.setBackgroundAccess(isActive: false)
    }
}
