//
//  ViewController.swift
//  PassiveDemoApp
//
//  Created by Hripsime on 2022-03-02.
//

import UIKit
import VSFoundation
import VSTT2
import Combine

final class ViewController: UIViewController {
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var startButton: UIButton!
    
    private var mapFanceExistCancellable: AnyCancellable?
    private var messgeCancellable: AnyCancellable?
    private var loadingCancellable: AnyCancellable?
    
    var indicator = UIActivityIndicatorView(style: .large)
    
    var viewModel: ViewModel?
    
    func setup(for user: User) {
        viewModel = ViewModel(with: user)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addIndicator()
        bindPublishers()
    }
    
    //MARK: Private helpers
    private func addIndicator() {
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        view.addSubview(indicator)
        
        indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    private func bindPublishers() {
        messgeCancellable = viewModel?.stopLoading
            .compactMap({ $0 })
            .sink { [weak self] stopLoading in
                if stopLoading {
                    self?.indicator.stopAnimating()
                }
            }
        
        loadingCancellable = viewModel?.showMessagePublisher
            .compactMap({ $0 })
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.showMessage()
                }
            }
    }
    
    @IBAction func startButtonAction(_ sender: UIButton) {
        startButton.isUserInteractionEnabled = false
        viewModel?.getItemBy(barcode: "7350109620030", completion: { (error) in
            DispatchQueue.main.async {
                if error == nil {
                    self.startButton.isUserInteractionEnabled = false
                    self.stopButton.backgroundColor = .red
                } else {
                    self.startButton.isUserInteractionEnabled = true
                }
            }
        })
    }
    
    @IBAction func stopButtonAction(_ sender: UIButton) {
        startButton.isUserInteractionEnabled = true
        viewModel?.stop()
        stopButton.backgroundColor = .systemGray
    }
    
    @IBAction func firstButtonAction(_ sender: UIButton) {
//        viewModel?.getItemBy(shelfName: "1")
        handleSyncButtonPressed(tag: sender.tag)
    }
    
    @IBAction func secondButtonAction(_ sender: UIButton) {
//        viewModel?.getItemBy(shelfName: "2")
        handleSyncButtonPressed(tag: sender.tag)
    }
    
    @IBAction func thirdButtonAction(_ sender: UIButton) {
//        viewModel?.getItemBy(shelfName: "3")
        handleSyncButtonPressed(tag: sender.tag)
    }

    func handleSyncButtonPressed(tag: Int) {
        let barcode: String
        switch tag {
        case 1: barcode = "7340011407003"
        case 2: barcode = "7312082001015"
        case 3: barcode = "7340191105256"
        case 4: barcode = "7350002402658"
        case 5: barcode = "7310865866356"
        case 6: barcode = "7394376614323"
        case 7: barcode = "7340011305071"
        case 8: barcode = "7350027795339"
        case 9: barcode = "7340011443056"
        case 10: barcode = "7340005403554"
        default: barcode = ""
        }

        viewModel?.getItemBy(barcode: barcode, completion: { (error) in
            DispatchQueue.main.async {
                if error == nil {
                    self.startButton.isUserInteractionEnabled = false
                    self.stopButton.backgroundColor = .red
                } else {
                    self.startButton.isUserInteractionEnabled = true
                }
            }
        })
    }
    
    func showMessage() {
        let alert = UIAlertController(title: viewModel?.messageTitle, message: viewModel?.messageDesc, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .default) { action in
            self.viewModel?.addCompletedTriggerEvent()
        }
        
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}

