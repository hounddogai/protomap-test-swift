import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped eligibility rollup calculation.
    protocol CappedEligibilityRollupStep {
        func describe() -> String
        func adjust(_ item: CappedEligibilityRollup, value: Double) -> Double
    }

    final class PercentCappedEligibilityRollupAdjuster: CappedEligibilityRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedEligibilityRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleCappedEligibilityRollupAdjuster: CappedEligibilityRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CappedEligibilityRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedEligibilityRollupAttemptsOffsetAdjuster: CappedEligibilityRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: CappedEligibilityRollup, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class TieredCappedEligibilityRollupAdjuster: CappedEligibilityRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedEligibilityRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped eligibility rollup steps in order and keeps a trace of each.
    final class CappedEligibilityRollupEngine {
        var steps: [any CappedEligibilityRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedEligibilityRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedEligibilityRollup) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedEligibilityRollupStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [CappedEligibilityRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedEligibilityRollupEngine() -> CappedEligibilityRollupEngine {
        return CappedEligibilityRollupEngine(
            steps: [
                PercentCappedEligibilityRollupAdjuster(percent: -21.8),
                LocaleCappedEligibilityRollupAdjuster(factors: ["retail": 0.94]),
                CappedEligibilityRollupAttemptsOffsetAdjuster(weight: 1.0),
                TieredCappedEligibilityRollupAdjuster(bounds: [1345.0, 8434.0], rates: [0.98, 0.9]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 48456.3
        )
    }
}
