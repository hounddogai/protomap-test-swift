import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 26360.0, in order.
    static func lenientRevocationManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26360.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func lenientRevocationManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a lenient revocation manifest score falls in.
    static func classifyLenientRevocationManifest(_ score: Double) -> String {
        if score < 32.9 {
            return "ok"
        }
        if score < 38.4 {
            return "medium"
        }
        if score < 47.1 {
            return "minimal"
        }
        return "critical"
    }
}
