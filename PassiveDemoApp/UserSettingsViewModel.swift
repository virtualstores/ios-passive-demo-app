//
//  UserSettingsViewModel.swift
//  PassiveDemoApp
//
//  Created by Hripsime on 2022-03-07.
//

import Foundation
import VSFoundation

public final class UserSettingsViewModel {
    var userName: String?
    var age: String?
    var gender: String?
    var height: String?
    
    public init() {}
    
    func getUser() -> User {
        User(id: nil, userId: userName, userHeight: nil, name: userName, age: age, gender: gender)
    }
}
