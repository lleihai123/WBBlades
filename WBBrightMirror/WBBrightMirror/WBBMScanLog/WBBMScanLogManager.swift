//
//  WBBMScanLogManager.swift
//  WBBrightMirror
//
//  Created by 朴惠姝 on 2021/4/27.
//

import Foundation

class WBBMScanLogManager {
    class func scanLog(logString: String) -> WBBMLogModel?{
       if logString.count == 0 {
           return nil
       }
       
       //scan system crash log
       if let logModel: WBBMLogModel = WBBMScanSystemLog.scanSystemLog(content: logString) {
           return logModel
       }
    
       //scan bugly crash log
       if let logModel: WBBMLogModel = WBBMScanBuglyLog.scanBuglyLog(content: logString) {
           return logModel
       }
       
       return nil
   }
}
