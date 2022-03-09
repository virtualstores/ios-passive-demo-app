//
//  UserSettingsViewController.swift
//  PassiveDemoApp
//
//  Created by Hripsime on 2022-03-07.
//

import Foundation
import UIKit

public class UserSettingsViewController: UIViewController, UITextFieldDelegate, UIActionSheetDelegate {
    @IBOutlet private weak var userNameTextField: UITextField!
    @IBOutlet private weak var userGenderTextField: UITextField!
    @IBOutlet private weak var userageTextField: UITextField!
    @IBOutlet private weak var saveButton: UIButton!

    var viewModel = UserSettingsViewModel()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.userNameTextField.addTarget(self, action: #selector(userNameFieldDidChange(_:)), for: .editingDidEnd)
        self.userageTextField.addTarget(self, action: #selector(ageFieldDidChange(_:)), for: .editingDidEnd)
        self.userGenderTextField.addTarget(self, action: #selector(selectGenderAction(textField:)), for: .touchDown)
    }

    @IBAction func saveButtonAction(_ sender: Any) {
        openMainView()
    }
    
    func openMainView() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        newViewController.setup(for: viewModel.getUser())
        self.present(newViewController, animated: true, completion: nil)
    }
    
    @objc func userNameFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            viewModel.userName = text
        }
    }
    
    @objc func ageFieldDidChange(_ textField: UITextField) {
        if let text = textField.text {
            viewModel.age = text
        }
    }
    
    func setupGender(_ text: String) {
        viewModel.gender = text
        userGenderTextField.text = text
        userageTextField.resignFirstResponder()
    }
    
    @objc func selectGenderAction(textField: UITextField) {
        let optionMenu = UIAlertController(title: nil, message: "Choose Gender", preferredStyle: .actionSheet)
           
        let genderMale = UIAlertAction(title: "MALE", style: .default) { action in
            self.setupGender(action.title ?? "")
        }
        
        let genderFemale = UIAlertAction(title: "FEMALE", style: .default) { action in
            self.setupGender(action.title ?? "")
        }

       optionMenu.addAction(genderMale)
       optionMenu.addAction(genderFemale)
       self.present(optionMenu, animated: true, completion: nil)
   }
}
