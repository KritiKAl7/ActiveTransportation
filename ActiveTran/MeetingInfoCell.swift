//
//  MeetingInfoCell.swift
//  ActiveTransportation
//
//  Created by shuopeng yin on 3/6/16.
//
//

import Foundation
import UIKit

class MeetingInfoCell: UITableViewCell {
    
    @IBOutlet weak var infoOwnerLabel: UILabel!
    
    @IBOutlet weak var meetingLocationLabel: UILabel!
    @IBOutlet weak var meetingTimeLabel: UILabel!
    
    
    @IBOutlet weak var travelDistanceLabel: UILabel!
   // should have a button for displaying map in the future 
   // @IBOutlet weak var titleLabel: UILabel!
}