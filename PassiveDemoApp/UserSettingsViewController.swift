//
//  UserSettingsViewController.swift
//  PassiveDemoApp
//
//  Created by Hripsime on 2022-03-07.
//

import Foundation
import UIKit

public class UserSettingsViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet private weak var userNameTextField: UITextField!
    @IBOutlet private weak var userGenderTextField: UITextField!
    @IBOutlet private weak var userageTextField: UITextField!
    @IBOutlet private weak var saveButton: UIButton!

    var viewModel = UserSettingsViewModel()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.userNameTextField.addTarget(self, action: #selector(userNameFieldDidChange(_:)), for: .editingDidEnd)
        self.userageTextField.addTarget(self, action: #selector(ageFieldDidChange(_:)), for: .editingDidEnd)
        self.userGenderTextField.addTarget(self, action: #selector(genderFieldDidChange(_:)), for: .editingDidEnd)
    }

    @IBAction func saveButtonAction(_ sender: Any) {
        viewModel.seveUserData()
        openMainView()
    }
    
    
    func openMainView() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        self.present(newViewController, animated: true, completion: nil)
    }
    
    @objc func userNameFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            viewModel.userName = text
        }
    }
    
    @objc func ageFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            viewModel.userName = text
        }
    }
    
    @objc func genderFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            viewModel.gender = text
        }
    }

}
