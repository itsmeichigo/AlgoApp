//
//  SettingsController.swift
//  AlgoApp
//
//  Created by Huong Do on 3/3/19.
//  Copyright © 2019 Huong Do. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingsController: UITableViewController {
    
    @IBOutlet weak var showsUnreadSwitch: UISwitch!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    @IBOutlet var titleLabels: [UILabel]!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureNavigationBar()
        
        Themer.shared.currentThemeDriver
            .drive(onNext: { [weak self] theme in
                self?.darkModeSwitch.isOn = theme == .dark
                self?.updateColors()
            })
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return Themer.shared.currentTheme == .light ? .default : .lightContent
    }

    private func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
    }
    
    private func configureView() {
        updateColors()
        
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        darkModeSwitch.isOn = Themer.shared.currentTheme == .dark
        showsUnreadSwitch.isOn = AppConfigs.shared.showsReadProblem
        
        darkModeSwitch.rx.isOn
            .map { $0 ? Theme.dark : Theme.light }
            .subscribe(onNext: {
                Themer.shared.currentTheme = $0
            })
            .disposed(by: disposeBag)
        
        showsUnreadSwitch.rx.isOn
            .map { !$0 }
            .subscribe(onNext: {
                AppConfigs.shared.showsReadProblem = $0
            })
            .disposed(by: disposeBag)
    }
    
    private func updateColors() {
        navigationController?.navigationBar.tintColor = .titleTextColor()
        navigationController?.navigationBar.barTintColor = .backgroundColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.titleTextColor()]
        
        tabBarController?.tabBar.tintColor = .secondaryColor()
        tabBarController?.tabBar.barTintColor = .backgroundColor()
        
        showsUnreadSwitch.onTintColor = .secondaryColor()
        darkModeSwitch.onTintColor = .secondaryColor()
        
        titleLabels.forEach({ label in
            label.textColor = .titleTextColor()
        })
        
        tableView.separatorColor = .borderColor()
        tableView.reloadData()
        view.backgroundColor = .backgroundColor()
        
        setNeedsStatusBarAppearanceUpdate()
    }

}

extension SettingsController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .primaryColor()
        
        if cell.accessoryType == .none {
            cell.selectionStyle = .none
        } else {
            cell.selectionStyle = .default
        }
        
        let colorView = UIView()
        colorView.backgroundColor = .backgroundColor()
        cell.selectedBackgroundView? = colorView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 28
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 28))
        view.backgroundColor = .backgroundColor()
        
        let label = UILabel(frame: CGRect(x: 8, y: 0, width: tableView.bounds.width - 16, height: 28))
        label.textColor = .subtitleTextColor()
        label.font = UIFont.systemFont(ofSize: 14)
        view.addSubview(label)
        
        switch section {
        case 0:
            label.text = "Problems"
        case 1:
            label.text = "Appearance"
        case 2:
            label.text = "Leetcode Daily"
        default:
            break
        }
        
        return view
    }
}
