import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 58914.0, in order.
    static func bedBoardEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58914.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func bedBoardEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a bed board entry code in its canonical BBE- form.
    static func normalizeBedBoardEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBE-") {
            return clean
        }
        return "BBE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func bedBoardEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
