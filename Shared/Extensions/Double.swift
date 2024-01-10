//
//  Double.swift
//  tvOS
//
//  Created by Fitzgerald Afful on 28/06/2021.
//

import Foundation


extension Double {

    private var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }

    func secondsToString() -> String {
        return formatter.string(from: self) ?? ""
    }

  func asString(style: DateComponentsFormatter.UnitsStyle) -> String {
    if(self == 0) { return "0:00" }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
    formatter.unitsStyle = style
    guard let formattedString = formatter.string(from: self) else { return "" }
    return formattedString
  }
}


func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
