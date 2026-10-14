import AcmePlatform
import Foundation

extension Pharmacy {
    static func inventoryRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.24
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a inventory record code in its canonical IR- form.
    static func normalizeInventoryRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IR-") {
            return clean
        }
        return "IR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInventoryRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("inventory-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a inventory record score falls in.
    static func classifyInventoryRecord(_ score: Double) -> String {
        if score < 31.2 {
            return "minimal"
        }
        if score < 39.4 {
            return "elevated"
        }
        if score < 46.6 {
            return "low"
        }
        if score < 98.1 {
            return "high"
        }
        return "medium"
    }
}
