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
    let tt2 = TT2(with: "https://gunnis-hp-central.ih.vs-office.se", apiKey: "kanelbulle")
    
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
        tt2.initialize(clientId: 1) { [weak self] error in
            if error == nil {
                guard let store = self?.tt2.activeStores.first(where: { $0.id == 18 }) else { return }

                self?.currentStore = store
                Logger(verbosity: .info).log(message: "StoreName: \(store.name)")
                self?.user = user
                self?.tt2.user.initializeUser(userId: user.id ?? "", completion: { (_) in

                })

                self?.tt2.initiate(store: store) { error in
                    Logger(verbosity: .info).log(message: "Active floor: \(self?.tt2.activeFloor?.name)")
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
            guard let point = itemPosition?.point else { return }
            self.tt2.navigation.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                do {
                    try self.tt2.navigation.start(startPosition: point)
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
            } else {
                completion(NSError())
            }
        }
    }
    
    public func addCompletedTriggerEvent() {
        guard let currentEvent = self.currentEvent?.toMessageShown else { return }
        tt2.analytics.addTriggerEvent(for: currentEvent)
        self.currentEvent = nil
    }
    
    public func createCustomEvent() {
        guard let id = tt2.activeFloor?.id else { return }
        let trigger = TriggerEvent.CoordinateTrigger(point: CGPoint(x: 5.0, y: 10.0), radius: 5, type: .enter)
        let event = TriggerEvent(rtlsOptionsId: id, name: "Testing", description: "Test description", eventType: .coordinateTrigger(trigger))
        self.tt2.events.add(event: event)
    }
    
    private func startNavigation() -> Bool {
        guard let location = tt2.activeFloor?.scanLocations?.first(where: { $0.type == .start }) else { return false }
        
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

        tt2.analytics.startVisit(deviceInformation: deviceInformation, tags: tags) { (result) in
            switch result {
            case .success(let visitId):
                print("VisitID", visitId)
                self.startCollectingHeatMapData()
            case .failure(let error):
                print("StartVisitError", error)
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
        analyticsMessgeCancellable = tt2.events.messageEventPublisher
            .compactMap({ $0 })
            .sink { [weak self] event in
                self?.currentEvent = event
                self?.messageTitle = event.name
                self?.messageDesc = event.description
                self?.showMessagePublisher.send(())

                // Use the keys found in struct DefaultMetaData to get information about the event when presenting
                let title = event.metaData["@title"]
                let description = event.metaData["@body"]
                let imageUrl = event.metaData["@imageUrl"]
                let type = event.metaData["@type"] // If the popup should be small or large
                // Present event

                // IMPORTANT: Don't forget to report to the analytics that this message was shown so that it gets tracked in the CMS
                guard let messageShownEvent = event.toMessageShown else { return }
                self?.tt2.analytics.addTriggerEvent(for: messageShownEvent)
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
