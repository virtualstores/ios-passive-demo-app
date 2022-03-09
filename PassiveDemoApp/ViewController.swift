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
    
    var indicator = UIActivityIndicatorView(style: .whiteLarge)
    
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
    
    @IBAction func startButtonAction(_ sender: Any) {
        startButton.isUserInteractionEnabled = false
        viewModel?.start()
    }
    
    @IBAction func stopButtonAction(_ sender: Any) {
        startButton.isUserInteractionEnabled = true
        viewModel?.stop()
    }
    
    @IBAction func firstButtonAction(_ sender: Any) {
        viewModel?.getItemByShelfName(name: "1")
    }
    
    @IBAction func secondButtonAction(_ sender: Any) {
        viewModel?.getItemByShelfName(name: "2")
    }
    
    @IBAction func thirdButtonAction(_ sender: Any) {
        viewModel?.getItemByShelfName(name: "3")
    }
    
    func showMessage() {
        let alert = UIAlertController(title: viewModel?.messageTitle, message: viewModel?.messageDesc, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

