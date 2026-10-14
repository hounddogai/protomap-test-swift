import AcmePlatform
import Foundation

extension Labs {
    /// Puts a specimen window code in its canonical SW- form.
    static func normalizeSpecimenWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SW-") {
            return clean
        }
        return "SW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func specimenWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.07
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
