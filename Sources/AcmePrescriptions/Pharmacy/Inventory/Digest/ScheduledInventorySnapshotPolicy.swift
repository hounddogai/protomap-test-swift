import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 57612.0, in order.
    static func scheduledInventorySnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57612.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledInventorySnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a scheduled inventory snapshot score falls in.
    static func classifyScheduledInventorySnapshot(_ score: Double) -> String {
        if score < 31.9 {
            return "critical"
        }
        if score < 32.4 {
            return "minimal"
        }
        if score < 68.0 {
            return "low"
        }
        return "watch"
    }

    /// Puts a scheduled inventory snapshot code in its canonical SIS- form.
    static func normalizeScheduledInventorySnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIS-") {
            return clean
        }
        return "SIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
