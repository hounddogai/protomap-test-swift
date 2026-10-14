import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a weighted risk score template score falls in.
    static func classifyWeightedRiskScoreTemplate(_ score: Double) -> String {
        if score < 14.3 {
            return "minimal"
        }
        if score < 88.8 {
            return "ok"
        }
        return "high"
    }

    static func weightedRiskScoreTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func weightedRiskScoreTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 22082.0, in order.
    static func weightedRiskScoreTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22082.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
