import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 60857.0, in order.
    static func manualWitnessDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60857.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualWitnessDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a manual witness draft code in its canonical MWD- form.
    static func normalizeManualWitnessDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MWD-") {
            return clean
        }
        return "MWD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualWitnessDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
