//
//  UserSettingsViewModel.swift
//  PassiveDemoApp
//
//  Created by Hripsime on 2022-03-07.
//

import Foundation
import VSFoundation

public class UserSettingsViewModel {
    var persistence = Persistence() 
    var userName: String?
    var age: Int?
    var gender: String?
    var height: String?
    
    public init() {}
    
    func seveUserData() {
        var object = User()
        object.name = userName
        object.age = age
        object.gender = gender

        do {
            try persistence.save(&object)
        } catch {
            Logger.init(verbosity: .silent).log(tag: Logger.createTag(fileName: #file, functionName: #function),
                                                message: "Save User Object SQLite error")
        }
    }
}
