import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeCappedAlertWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a capped alert window code in its canonical CAW- form.
    static func normalizeCappedAlertWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CAW-") {
            return clean
        }
        return "CAW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedAlertWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-alert-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 59730.0, in order.
    static func cappedAlertWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59730.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
