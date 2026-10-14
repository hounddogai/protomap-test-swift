import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a regional float pool override code in its canonical RFPO- form.
    static func normalizeRegionalFloatPoolOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFPO-") {
            return clean
        }
        return "RFPO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalFloatPoolOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-float-pool-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func regionalFloatPoolOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.36
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
