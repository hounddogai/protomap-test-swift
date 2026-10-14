import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 33471.0, in order.
    static func regionalHandoffManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33471.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a regional handoff manifest score falls in.
    static func classifyRegionalHandoffManifest(_ score: Double) -> String {
        if score < 41.3 {
            return "high"
        }
        if score < 76.0 {
            return "critical"
        }
        if score < 94.9 {
            return "ok"
        }
        if score < 99.9 {
            return "watch"
        }
        return "minimal"
    }
}
