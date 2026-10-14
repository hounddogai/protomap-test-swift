import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a manual denial agreement code in its canonical MDA- form.
    static func normalizeManualDenialAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MDA-") {
            return clean
        }
        return "MDA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualDenialAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 39428.0, in order.
    static func manualDenialAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39428.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualDenialAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
