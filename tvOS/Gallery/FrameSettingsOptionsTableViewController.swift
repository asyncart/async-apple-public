//
//  FrameSettingsOptionsTableViewController.swift
//  tvOS
//
//  Created by Francis Li on 6/10/20.
//

import UIKit

class FrameSettingsOptionsTableViewController: FrameSettingsTableViewController {
    var settingsKey: FrameSettingsKey!
    var options: [Any]!
    var values: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let settingsKey = settingsKey {
            title = String(describing: settingsKey)
        }
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let value = settings.valueForKey(settingsKey) as? String,
            let row = values.firstIndex(of: value),
            let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) {
            return [cell]
        }
        return []
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FrameSettingsTableViewCell {
            let value = settings.valueForKey(settingsKey) as? String ?? values.first
            cell.setChecked(value == values[indexPath.row])
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        settings.setValue(values[indexPath.row], forKey: settingsKey)
        if let cell = tableView.cellForRow(at: indexPath) as? FrameSettingsTableViewCell {
            cell.setSelectedAnimated { [weak self] in
                if let rows = tableView.indexPathsForVisibleRows {
                    for indexPath in rows {
                        if let cell = tableView.cellForRow(at: indexPath) {
                            self?.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FrameSettingsOption", for: indexPath)
        cell.textLabel?.text = String(describing: options[indexPath.row])
        return cell
    }
}
