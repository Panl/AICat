//
//  Date+Extension.swift
//  AICat
//
//  Created by Lei Pan on 2023/3/19.
//
import Foundation

extension Date {

    var timeInSecond: Int {
        let timeStamp = Int(timeIntervalSince1970)
        return timeStamp
    }

    var timeInMillSecond: Int {
        let millisecond = Int(round(timeIntervalSince1970*1000))
        return millisecond
    }

    func toFormat(_ format: String = "yyyy.MM.dd HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
