import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackAccessionReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-accession-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 23455.0, in order.
    static func fallbackAccessionReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23455.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeFallbackAccessionReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a fallback accession reservation code in its canonical FAR- form.
    static func normalizeFallbackAccessionReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FAR-") {
            return clean
        }
        return "FAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
