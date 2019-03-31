//
//  SortOptionsViewController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/31/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import PanModal
import RxSwift
import RxCocoa

class SortOptionsViewController: UIViewController {
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    private func configureView() {
        view.backgroundColor = .backgroundColor()
        
        pickerView.backgroundColor = .backgroundColor()
        pickerView.dataSource = self
        pickerView.delegate = self
        if let index = SortOption.allCases.firstIndex(where: { $0 == AppConfigs.shared.sortOption }) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
        
        doneButton.layer.cornerRadius = 8.0
        doneButton.backgroundColor = .appPurpleColor()
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.rx.tap
            .subscribe(onNext: { [unowned self] in self.updateSortOption() })
            .disposed(by: disposeBag)
    }
    
    private func updateSortOption() {
        let row = pickerView.selectedRow(inComponent: 0)
        AppConfigs.shared.sortOption = SortOption.allCases[row]
        dismiss(animated: true, completion: nil)
    }
}

extension SortOptionsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return SortOption.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = SortOption.allCases[row].displayText
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()])
    }
}

extension SortOptionsViewController: PanModalPresentable {
    
    var isPanScrollEnabled: Bool {
        return false
    }
    
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var shortFormHeight: PanModalHeight {
        let height: CGFloat = 310.0
        return .contentHeight(height)
    }
    
    var longFormHeight: PanModalHeight {
        return shortFormHeight
    }
    
    var showDragIndicator: Bool {
        return false
    }
}
