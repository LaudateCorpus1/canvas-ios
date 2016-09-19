//
//  CourseCell.swift
//  Teach
//
//  Created by Derrick Hathaway on 4/11/16.
//  Copyright © 2016 Instructure. All rights reserved.
//

import Foundation
import UIKit
import ReactiveCocoa
import EnrollmentKit

class CourseCell: EnrollmentCollectionViewCell {
    
    @IBOutlet weak var customizeButton: UIButton?
    @IBOutlet weak var announceButtonView: UIView?
    @IBOutlet weak var innerAnnounceButtonView: UIButton?
    @IBOutlet weak var announceButton: UIButton?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    
    var customize: UIButton->() = {_ in}
    var makeAnnouncement: ()->() = {}
    
    private var disposable: CompositeDisposable = CompositeDisposable()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        makeEvenMoreBeautiful()
        beginObservingProperties()
        makeAccessible()
        announceButton?.setImage(.icon(.announcements), forState: .Normal)
        customizeButton?.setImage(.icon(.edit, filled: true), forState: .Normal)
    }
    
    // MARK: Content
    
    func beginObservingProperties() {
        let producer = enrollment.producer
        if let t = titleLabel?.rac_text { t <~ producer.map { $0?.name ?? "" } }
        if let s = subtitleLabel?.rac_text { s <~ producer.map { $0?.shortName ?? "" } }
    }
    
    var viewModel: CourseViewModel? {
        didSet {
            customize = {_ in }
            makeAnnouncement = {}
            enrollment.value = viewModel?.enrollment.value
            
            if let vm = viewModel {
                customize = vm.customize
                makeAnnouncement = vm.makeAnAnnouncement
            }
        }
    }
    
    // MARK: Appearance
    
    func makeEvenMoreBeautiful() {
        announceButtonView?.layer.cornerRadius = 21
        innerAnnounceButtonView?.layer.cornerRadius = 19
        innerAnnounceButtonView?.backgroundColor = .whiteColor()
        tintColor = .whiteColor()
        layer.borderWidth = 2.0
        if let a = announceButtonView { contentView.bringSubviewToFront(a) }
    }
    
    override func colorUpdated(color: UIColor) {
        super.colorUpdated(color)
        announceButtonView?.backgroundColor = color
        layer.borderColor = color.CGColor
        innerAnnounceButtonView?.tintColor = color
    }
    
    
    // MARK: A11y
    
    func makeAccessible() {
        accessibilityElements = []
        
        isAccessibilityElement = true
        rac_a11yLabel <~ enrollment.producer.map { ($0?.name ?? "") + " — " + ($0?.shortName ?? "") }
        
        let announceTitle = NSLocalizedString("Make an Announcement", comment: "Make an announcement accessiblity text")
        let announceAction = UIAccessibilityCustomAction(name: announceTitle, target: self, selector: #selector(makeAnAnnouncement(_:)))
        
        let customizeTitle = NSLocalizedString("Customize", comment: "Customize course action title")
        let customizeAction = UIAccessibilityCustomAction(name: customizeTitle, target: self, selector: #selector(customizeCourse(_:)))
        
        accessibilityCustomActions = [announceAction, customizeAction]
    }

    
    // MARK: Actions
    
    @IBAction func customizeCourse(sender: AnyObject) {
        if let button = customizeButton {
            customize(button)
        }
    }
    
    @IBAction func makeAnAnnouncement(sender: AnyObject) {
        makeAnnouncement()
    }
}