import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 39708.0, in order.
    static func lenientProgramProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39708.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a lenient program profile code in its canonical LPP- form.
    static func normalizeLenientProgramProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LPP-") {
            return clean
        }
        return "LPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientProgramProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientProgramProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-program-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
