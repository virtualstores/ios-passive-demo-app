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
        let object = User()
        object.userId = userName
        object.age = age
        object.gender = gender

        return object
    }
}
