import AcmePlatform
import Foundation

extension CareManagement {
    static func programRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a program record score falls in.
    static func classifyProgramRecord(_ score: Double) -> String {
        if score < 54.1 {
            return "medium"
        }
        if score < 81.4 {
            return "critical"
        }
        if score < 82.5 {
            return "low"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 82115.0, in order.
    static func programRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82115.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
