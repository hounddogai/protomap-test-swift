import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a discharge plan profile code in its canonical DPP- form.
    static func normalizeDischargePlanProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPP-") {
            return clean
        }
        return "DPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDischargePlanProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("discharge-plan-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
