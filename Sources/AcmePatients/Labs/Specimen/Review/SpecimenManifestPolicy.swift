import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 42250.0, in order.
    static func specimenManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42250.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a specimen manifest score falls in.
    static func classifySpecimenManifest(_ score: Double) -> String {
        if score < 70.4 {
            return "watch"
        }
        if score < 95.6 {
            return "minimal"
        }
        return "ok"
    }

    static func specimenManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
