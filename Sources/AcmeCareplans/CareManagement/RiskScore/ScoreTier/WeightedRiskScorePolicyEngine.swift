import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted risk score policy calculation.
    protocol WeightedRiskScorePolicyStep {
        func describe() -> String
        func adjust(_ item: WeightedRiskScorePolicy, value: Double) -> Double
    }

    final class FlaggedWeightedRiskScorePolicyAdjuster: WeightedRiskScorePolicyStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: WeightedRiskScorePolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedRiskScorePolicyAdjuster: WeightedRiskScorePolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedRiskScorePolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedRiskScorePolicyAdjuster: WeightedRiskScorePolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedRiskScorePolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted risk score policy steps in order and keeps a trace of each.
    final class WeightedRiskScorePolicyEngine {
        var steps: [any WeightedRiskScorePolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRiskScorePolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedRiskScorePolicy) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [WeightedRiskScorePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedRiskScorePolicyEngine(_ flags: Kit.Flags.Registry) -> WeightedRiskScorePolicyEngine {
        return WeightedRiskScorePolicyEngine(
            steps: [
                FlaggedWeightedRiskScorePolicyAdjuster(
                    flags: flags,
                    flag: "weighted-risk-score-policy-weighted",
                    percent: -3.9
                ),
                TieredWeightedRiskScorePolicyAdjuster(
                    bounds: [1125.0, 4037.0, 6273.0, 8977.0],
                    rates: [1.1, 0.81, 1.01, 1.06]
                ),
                RoundingWeightedRiskScorePolicyAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 21405.8
        )
    }
}
