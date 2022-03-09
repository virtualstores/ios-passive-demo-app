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

public class ViewModel {
    var tt2 = TT2()
    
    public var stopLoading: CurrentValueSubject<Bool?, Never> = .init(nil)
    public var showMessagePublisher: CurrentValueSubject<Void?, Never> = .init(nil)
    public var currentStore: TT2Store?
    
    public var messageTitle: String?
    public var messageDesc: String?
    
    private var storessCancellable: AnyCancellable?
    private var positionCancellable: AnyCancellable?
    private var collectHeatmapCancellable: AnyCancellable?
    private var analyticsMessgeCancellable: AnyCancellable?
    
    private var messageIDs: [String] = []
    
    public init() {
        tt2.initialize(with: "https://gunnis-hp-central.ih.vs-office.se/api/v1", apiKey: "kanelbulle", clientId: 1, completion: { [weak self] error in
            if error == nil {
                guard let activeStores = self?.tt2.activeStores, !activeStores.isEmpty else { return }
            
                let store = activeStores[0]
                Logger(verbosity: .info).log(message: "Store name: \(store.name)")
                self?.currentStore = store
                            
                self?.tt2.initiateStore(store: store, completion: { error in
                    self?.stopLoading.send(true)
                })
            }
        })
    
        bindPublishers()
    }
    
    public func start() {
        startNavigation()
        startVisit()
        tt2.setBackgroundAccess(isActive: true)
    }
    
    public func getItemByShelfName(name: String) {
        tt2.position.getByShelfName(shelfName: name) { itemPosition in
            self.tt2.navigation.stop()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                do {
                    try self.tt2.navigation.compassStartNavigation(startPosition: itemPosition.point)
                } catch {
                    Logger.init().log(message: "GetItemByShelfName startUpdatingLocation error")
                }
            }
        }
    }
    
    public func getItemByShelfName(barcode: String) {
        tt2.position.getByBarcode(barcode: barcode) { item in
        }
    }
    
    private func startNavigation() {
        guard let location = tt2.rtlsOption?.scanLocations?.first(where: { $0.type == .start }) else { return }

        do {
            //try self.tt2.navigation.start(startPosition: location.point, startAngle: location.direction)
            try self.tt2.navigation.compassStartNavigation(startPosition: location.point)
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
        
        let tags: [String : String] = ["age":"67", "gender":"MALE", "userId": "Testing"]

        tt2.analytics.startVisit(deviceInformation: deviceInformation, tags: tags)
        
        collectHeatmapCancellable = tt2.analytics.startHeatMapCollectingPublisher
            .compactMap({ $0 })
            .sink(receiveCompletion: { _ in
                Logger.init().log(message: "startHeatMapCollectingPublisher error")
            }, receiveValue: { [weak self] event in
                self?.startCollectingHeatMapData()
            })
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
                let key = event.name + event.description
                if self?.messageIDs.contains(key) == false {
                    self?.messageIDs.append(key)
                    
                    self?.messageTitle = event.name
                    self?.messageDesc = event.description
                    self?.showMessagePublisher.send(())
                }
            }
    }
    
    func stop() {
        tt2.navigation.stop()
        tt2.analytics.stopVisit()
        tt2.setBackgroundAccess(isActive: true)
    }
}
