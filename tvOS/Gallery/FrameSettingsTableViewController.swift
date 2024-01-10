//
//  FrameSettingsTableViewController.swift
//  tvOS
//
//  Created by Francis Li on 6/10/20.
//

import UIKit

private let FrameSettingsTableViewInset: CGFloat = 20

class FrameSettingsTableViewCell: UITableViewCell {
    weak var containerView: UIView!
    weak var containerBackgroundView: UIView!
    weak var customAccessoryView: UIView!

    override var isUserInteractionEnabled: Bool {
        didSet {
            contentView.alpha = isUserInteractionEnabled ? 1 : 0.5
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        /// add our internal container view
        let containerView = UIView(frame: contentView.bounds)
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.insertSubview(containerView, at: 0)
        self.containerView = containerView

        /// add our internal background view
        let containerBackgroundView = UIView(frame: containerView.bounds)
        containerBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerBackgroundView.backgroundColor = UIColor(named: "gray")
        containerBackgroundView.layer.cornerRadius = 5
        containerView.addSubview(containerBackgroundView)
        self.containerBackgroundView = containerBackgroundView

        /// replace the default tvOS disclosure indicator with our custom asset as needed
        if accessoryType == .disclosureIndicator {
            accessoryType = .none
            let imageView = UIImageView(image: UIImage(named: "disclosureIndicator"))
            imageView.sizeToFit()
            imageView.frame.origin = CGPoint(x: containerBackgroundView.bounds.width - FrameSettingsTableViewInset - imageView.frame.width, y: floor((containerBackgroundView.bounds.height - imageView.frame.height) / 2))
            imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
            containerBackgroundView.addSubview(imageView)
            customAccessoryView = imageView
        }
        /// move the labels into our container view so they will adjust on focus
        if let textLabel = textLabel {
            textLabel.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            containerBackgroundView.addSubview(textLabel)
        }
        if let detailTextLabel = detailTextLabel {
            detailTextLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
            containerBackgroundView.addSubview(detailTextLabel)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = isFocused ? contentView.bounds :contentView.bounds.inset(by: UIEdgeInsets(top: 0, left: FrameSettingsTableViewInset, bottom: 0, right: FrameSettingsTableViewInset))
        if let detailTextLabel = detailTextLabel {
            detailTextLabel.frame.origin.x = containerBackgroundView.bounds.width - FrameSettingsTableViewInset - detailTextLabel.frame.width - (customAccessoryView != nil ? customAccessoryView.frame.width + FrameSettingsTableViewInset : 0)
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        containerBackgroundView.backgroundColor = isFocused ? UIColor(named: "asyncPurple") : UIColor(named: "gray")
        let frame = isFocused ? bounds : bounds.inset(by: UIEdgeInsets(top: 0, left: FrameSettingsTableViewInset, bottom: 0, right: FrameSettingsTableViewInset))
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.containerView.frame = frame
        }
    }

    func setSelectedAnimated(completion: @escaping () -> ()) {
        UIView.animate(withDuration: 0.125, animations: { [weak self] in
            self?.containerBackgroundView.frame = self?.containerView.bounds.inset(by: UIEdgeInsets(top: 0, left: FrameSettingsTableViewInset, bottom: 0, right: FrameSettingsTableViewInset)) ?? .zero
        }, completion: { [weak self] (finished) in
            UIView.animate(withDuration: 0.125, animations: { [weak self] in
                self?.containerBackgroundView.frame = self?.containerView.bounds ?? .zero
            }, completion: { (finished) in
                completion()
            })
        })
    }

    func setChecked(_ checked: Bool) {
        if checked {
            let imageView = UIImageView(image: UIImage(named: "checkmark"))
            imageView.sizeToFit()
            imageView.frame.origin = CGPoint(x: containerBackgroundView.bounds.width - FrameSettingsTableViewInset - imageView.frame.width, y: floor((containerBackgroundView.bounds.height - imageView.frame.height) / 2))
            imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
            containerBackgroundView.addSubview(imageView)
            customAccessoryView = imageView
        } else {
            customAccessoryView?.removeFromSuperview()
            customAccessoryView = nil
        }
        setNeedsLayout()
    }
}

class FrameSettingsTableViewController: UITableViewController {
    var settings: FrameSettings!
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        title = NSLocalizedString("Frame Settings", comment: "")

        tableView.rowHeight = 50
        tableView.separatorInset = UIEdgeInsets(top: 0, left: FrameSettingsTableViewInset, bottom: 0, right: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        if !isMovingToParent && animated {
            tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? FrameSettingsOptionsTableViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            vc.settings = settings
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 1:
                    vc.settingsKey = .frameColor
                    vc.options = FrameColor.allCases
                    vc.values = FrameColor.allCases.map({ $0.rawValue })
                default:
                    break
                }
            case 1:
                switch indexPath.row {
                case 1:
                    vc.settingsKey = .matColor
                    vc.options = MatColor.allCases
                    vc.values = MatColor.allCases.map({ $0.rawValue })
                default:
                    break
                }
            default:
                break
            }
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: section)
            view.textLabel?.textColor = .white
            view.textLabel?.font = UIFont(name: "Chivo-Regular", size: 20)
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? FrameSettingsTableViewCell {
            switch indexPath.section {
            case 0:
                switch indexPath.row {
                case 0:
                    cell.detailTextLabel?.text = settings.isFrameVisible ? NSLocalizedString("ON", comment: "") : NSLocalizedString("OFF", comment: "")
                case 1:
                    cell.detailTextLabel?.text = String(describing: settings.frameColor)
                default:
                    break
                }
            case 1:
                switch indexPath.row {
                case 0:
                    cell.detailTextLabel?.text = settings.isMatboardVisible ? NSLocalizedString("ON", comment: "") : NSLocalizedString("OFF", comment: "")
                case 1:
                    cell.detailTextLabel?.text = String(describing: settings.matColor)
                default:
                    break
                }
            case 2:
                switch indexPath.row {
                case 0:
                    cell.detailTextLabel?.text = settings.isBlurredEdgesVisible ? NSLocalizedString("ON", comment: "") : NSLocalizedString("OFF", comment: "")
                case 1:
                    cell.detailTextLabel?.text = settings.isZoomFillEnabled ? NSLocalizedString("ON", comment: "") : NSLocalizedString("OFF", comment: "")
                default:
                    break
                }
                cell.isUserInteractionEnabled = !settings.isFrameVisible && !settings.isMatboardVisible
            case 3:
                switch indexPath.row {
                case 0:
                    cell.detailTextLabel?.text = String(describing: settings.orientation)
                default:
                    break
                }
            default:
                break
            }
            cell.setNeedsLayout()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? FrameSettingsTableViewCell {
            cell.setSelectedAnimated { [weak self] in
                guard let self = self else { return }
                switch indexPath.section {
                case 0:
                    switch indexPath.row {
                    case 0:
                        self.settings.isFrameVisible = !self.settings.isFrameVisible
                        TrackingEvent.frameEnabled.send()
                    default:
                        break
                    }
                case 1:
                    switch indexPath.row {
                    case 0:
                        self.settings.isMatboardVisible = !self.settings.isMatboardVisible
                        TrackingEvent.matboardEnabled.send()
                    default:
                        break
                    }
                case 2:
                    switch indexPath.row {
                    case 0:
                        self.settings.isBlurredEdgesVisible = !self.settings.isBlurredEdgesVisible
                        TrackingEvent.blurredEdgesEnabled.send()
                    case 1:
                        self.settings.isZoomFillEnabled = !self.settings.isZoomFillEnabled
                        TrackingEvent.zoomFillEnabled.send()
                    default:
                        break
                    }
                case 3:
                    switch indexPath.row {
                    case 0:
                        self.settings.orientation = self.settings.orientation == .landscape ? .portrait : .landscape
                        TrackingEvent.orientationChanged.send()
                    default:
                        break
                    }
                default:
                    break
                }
                self.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
                if indexPath.section == 0 || indexPath.section == 1 {
                    self.tableView.reloadSections(IndexSet(integer: 2), with: .none)
                }
            }
        }
    }
}
