//
//  NTMonitor.swift
//  StartupProjectSampleA
//
//  Created by Towhid on 5/25/15.
//  Copyright (c) 2015 Towhid (Selise.ch). All rights reserved.
//

import UIKit
import CoreDataStack

enum NTFrequency: Int{
    case Hour = 0
    case Day = 1
    case Week = 2
    case Mounth = 3
    case Allways = 4
}

public class NTUnit: NGObject{
    
    private struct StaticFormatter {
        static var defaultDateFormatter: DateFormatter = DateFormatter()
    }
    
    class func defaultDateFormatter() -> DateFormatter{
        //
        let formatter = StaticFormatter.defaultDateFormatter
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss a"
        return formatter
    }
    
    @objc public var type: NSString?
    @objc public var frequency: NSNumber?
    @objc public var lastFireDate: NSDate?
    @objc public var exponentialRate: NSNumber?
    @objc public var multiplier: NSNumber?
    @objc public var multiplierInitialValue: NSNumber?
    @objc public var multiplierMaxLimit: NSNumber?
    
    @objc public override func updateDate(_ dateStr: String!) -> Date! {
        return NTUnit.defaultDateFormatter().date(from: dateStr)
    }
    
    @objc public override func serializeDate(_ date: Date!) -> String! {
        return NTUnit.defaultDateFormatter().string(from: date as Date)
    }
}

public class NTMonitor: NSObject {
   
    func registerMonitoring(type: String, frequency: NTFrequency, expRate: Double = 1.0, multiplier: Double = 1.0, maxLimit: Double = 12.0, startDate: NSDate? = nil){
        //
        if let _ = UserDefaults.standard.object(forKey: type){
            print("\(type) is already registered")
            return
        }
        insertMonitoring(type: type, frequency: frequency, exponentialRate: expRate, multiplierInitialValue: multiplier, multiplierMaxLimit: maxLimit, startDate: startDate)
    }
    
    func unregisterMonitoring(type: String){
        //
        UserDefaults.standard.removeObject(forKey: type)
        UserDefaults.standard.synchronize()
    }
    
    /*
    * Return true menas, caller should dispatch the notification
    */
    
    func shouldFire(type:String, nowDate: NSDate = NSDate()) -> Bool{
        //
        if let obj = unitFor(type: type){
            if (obj.lastFireDate == nil || obj.frequency == nil){
                updateMonitoring(obj, type: type, date: nowDate)
                return true
            }
            if let oldFireDate = obj.lastFireDate{
                //
                let compareResult = nowDate.compare(oldFireDate as Date)
                let isDecendingOrSame = (compareResult == ComparisonResult.orderedDescending || compareResult == ComparisonResult.orderedSame)
                
                if isDecendingOrSame{
                    let frequency = NTFrequency(rawValue: obj.frequency!.intValue)!
                    let multiplier = obj.multiplier!
                    let interval = nowDate.timeIntervalSince(oldFireDate as Date)
                    let isTrue = checkInterval(interval: interval, frequency: frequency, multiplier: multiplier.doubleValue)
                    if isTrue{
                        updateMonitoring(obj, type: type, date: nowDate)
                    }
                    return isTrue
                }
                //
            }
        }
        return false
    }
    
    private func checkInterval(interval: TimeInterval, frequency: NTFrequency, multiplier: Double = 1.0) -> Bool{
        //
        if frequency == NTFrequency.Hour{
            return interval/(multiplier*60*60) >= 1.0 ? true : false
        }
        else if frequency == NTFrequency.Day{
            return interval/(multiplier*24*60*60) >= 1.0 ? true : false
        }
        else if frequency == NTFrequency.Week{
            return interval/(multiplier*7*24*60*60) >= 1.0 ? true : false
        }
        else if frequency == NTFrequency.Mounth{
            return interval/(multiplier*30*24*60*60) >= 1.0 ? true : false
        }
        else {
            //NTFrequency.Allways
            return interval/(multiplier*1.0) >= 1.0 ? true : false
        }
    }
    
    private func updateMonitoring(_ objx: NTUnit?, type: String, date: NSDate){
        guard let obj = objx else {
            return
        }
        obj.lastFireDate = date
        let flier = obj.multiplier!.doubleValue * obj.exponentialRate!.doubleValue
        //If multiplierMaxLimit <= 0 then never meet the initial multiplier
        if ((obj.multiplierMaxLimit?.doubleValue)! <= 0){
            obj.multiplier = NSNumber(value: flier)
        }else{
            obj.multiplier = (flier <= (obj.multiplierMaxLimit?.doubleValue)!) ? NSNumber(value: flier) : obj.multiplierInitialValue
        }
        setUnit(obj: obj, forType: type)
    }
    
    private func insertMonitoring(type: String, frequency: NTFrequency, exponentialRate: Double, multiplierInitialValue: Double, multiplierMaxLimit: Double, startDate: NSDate?){
        //
        let obj = NTUnit(info: ["type" : type
            , "frequency" : NSNumber(value: frequency.rawValue)
            , "exponentialRate" : NSNumber(value: exponentialRate)
            , "multiplier" : NSNumber(value: multiplierInitialValue)
            , "multiplierInitialValue" : NSNumber(value: multiplierInitialValue)
            , "multiplierMaxLimit" : NSNumber(value: multiplierMaxLimit)])
        if let lastFireDate = startDate{
            obj?.lastFireDate = lastFireDate
        }
        setUnit(obj: obj!, forType: type)
    }
    
    private func unitFor(type:String) -> NTUnit? {
        
        if let archived = UserDefaults.standard.object(forKey: type) as? Data{
            let obj = NSKeyedUnarchiver.unarchiveObject(with: archived) as? NTUnit
            return obj
        }
        return nil
    }
    
    private func setUnit(obj: NTUnit, forType:String){
        
        let archiver = NSKeyedArchiver.archivedData(withRootObject: obj)
        UserDefaults.standard.set(archiver, forKey: forType)
        UserDefaults.standard.synchronize()
    }
    
}
