import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 60481.0, in order.
    static func shiftAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60481.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeShiftAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a shift agreement code in its canonical SA- form.
    static func normalizeShiftAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SA-") {
            return clean
        }
        return "SA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeShiftAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("shift-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
