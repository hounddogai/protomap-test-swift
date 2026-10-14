import AcmePlatform
import Foundation

extension BedManagement {
    static func manualTransferGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.16
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualTransferGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-transfer-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func manualTransferGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a manual transfer group code in its canonical MTG- form.
    static func normalizeManualTransferGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MTG-") {
            return clean
        }
        return "MTG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
