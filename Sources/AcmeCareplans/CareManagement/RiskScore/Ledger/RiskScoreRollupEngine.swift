import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score rollup calculation.
    protocol RiskScoreRollupModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreRollup, value: Double) -> Double
    }

    final class FlaggedRiskScoreRollupAdjuster: RiskScoreRollupModifier {
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

        func adjust(_ item: RiskScoreRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRiskScoreRollupAdjuster: RiskScoreRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRiskScoreRollupAdjuster: RiskScoreRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RiskScoreRollupAttemptsOffsetAdjuster: RiskScoreRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: RiskScoreRollup, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingRiskScoreRollupAdjuster: RiskScoreRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRiskScoreRollupAdjuster: RiskScoreRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the risk score rollup steps in order and keeps a trace of each.
    final class RiskScoreRollupEngine {
        var steps: [any RiskScoreRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RiskScoreRollup) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [RiskScoreRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRiskScoreRollupEngine(_ flags: Kit.Flags.Registry) -> RiskScoreRollupEngine {
        return RiskScoreRollupEngine(
            steps: [
                FlaggedRiskScoreRollupAdjuster(flags: flags, flag: "risk-score-rollup-tiered", percent: 8.0),
                TieredRiskScoreRollupAdjuster(bounds: [1949.0, 4676.0, 9355.0], rates: [1.04, 1.15, 1.04]),
                CapRiskScoreRollupAdjuster(cap: 10886.0),
                RiskScoreRollupAttemptsOffsetAdjuster(weight: 0.85),
                RoundingRiskScoreRollupAdjuster(step: 5.0),
                MinimumRiskScoreRollupAdjuster(minimum: 47.2),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 40243.4
        )
    }
}
