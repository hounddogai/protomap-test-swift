import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledInventoryWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-inventory-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func scheduledInventoryWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a scheduled inventory window code in its canonical SIW- form.
    static func normalizeScheduledInventoryWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIW-") {
            return clean
        }
        return "SIW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
