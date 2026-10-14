import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a modality slot code in its canonical MS- form.
    static func normalizeModalitySlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MS-") {
            return clean
        }
        return "MS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func modalitySlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.07
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalitySlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
