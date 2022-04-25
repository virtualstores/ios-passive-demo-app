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
    private var floorChangeCancellable: AnyCancellable?
    
    private var currentEvent: TriggerEvent?
    private var user: User?
    
    public init(with user: User) {
        let connection = ServerConnection(apiKey: "kanelbulle", serverAddress: "https://gunnis-hp-central.ih.vs-office.se", mqttAddress: nil, storeId: 0)
        tt2.initialize(with: connection.serverAddress!, apiKey: connection.apiKey!, clientId: 1) { [weak self] error in
            if error == nil {
                guard let store = self?.tt2.activeStores.first(where: { $0.id == 18 }) else { return }

                self?.currentStore = store
                Logger(verbosity: .info).log(message: "StoreName: \(store.name)")
                self?.user = user
                self?.tt2.userSettings.setUser(user: user)

                self?.tt2.initiateStore(store: store) { error in
                    Logger(verbosity: .info).log(message: "Active floor: \(self?.tt2.rtlsOption?.name)")
                    self?.stopLoading.send(true)
                }
            }
        }
        
        bindPublishers()
    }
    
    public func start() -> Bool {
        if startNavigation() {
            startVisit()
            return true
        }
        return false
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
    
    public func getItemBy(barcode: String, completion: @escaping (Error?) -> Void) {
        tt2.position.getBy(barcode: barcode) { (item) in
            if let itemPosition = item?.itemPosition {
                do {
                    if !self.tt2.navigation.isActive {
                        self.startVisit()
                        completion(nil)
                    }
                    try self.tt2.navigation.syncPosition(position: itemPosition)
                } catch {
                    print("StartingError: \(error.localizedDescription)")
                    completion(error)
                }
            }
        }
    }
    
    public func addCompletedTriggerEvent() {
        guard let currentEvent = self.currentEvent?.toMessageShown else { return }
        tt2.analytics.addTriggerEvent(for: currentEvent)
        self.currentEvent = nil
    }
    
    public func createCustomEvent() {
        guard let id = tt2.rtlsOption?.id else { return }
        let trigger = TriggerEvent.CoordinateTrigger(point: CGPoint(x: 5.0, y: 10.0), radius: 5)
        let event = TriggerEvent(rtlsOptionsId: id, name: "Testing", description: "Test description", eventType: .coordinateTrigger(trigger))
        self.tt2.analytics.evenManager.addEvent(event: event)
    }
    
    private func startNavigation() -> Bool {
        guard let location = tt2.rtlsOption?.scanLocations?.first(where: { $0.type == .start }) else { return false }
        
        do {
            try self.tt2.navigation.start(startPosition: location.point)
            Logger(verbosity: .info).log(message: "StartPoint: \(location.point), \(location.direction)")
//            try self.tt2.navigation.start(startPosition: location.point, startAngle: location.direction)
            return true
        } catch {
            Logger.init().log(message: "startUpdatingLocation error")
        }
        return false
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

      floorChangeCancellable = tt2.floorChangePublisher
        .compactMap { $0 }
        .sink(receiveValue: { floorName in
            self.messageTitle = "Changed floor to: \(floorName)"
            self.messageDesc = nil
            self.showMessagePublisher.send(())
        })
    }
    
    func stop() {
        tt2.navigation.stop()
        tt2.analytics.stopVisit()
    }
}
