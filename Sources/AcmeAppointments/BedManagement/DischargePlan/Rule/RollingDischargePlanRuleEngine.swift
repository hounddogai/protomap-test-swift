import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling discharge plan rule calculation.
    protocol RollingDischargePlanRuleAdjuster {
        func describe() -> String
        func adjust(_ item: RollingDischargePlanRule, value: Double) -> Double
    }

    final class PercentRollingDischargePlanRuleAdjuster: RollingDischargePlanRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingDischargePlanRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRollingDischargePlanRuleAdjuster: RollingDischargePlanRuleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingDischargePlanRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RollingDischargePlanRuleUpdatedAtOffsetAdjuster: RollingDischargePlanRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RollingDischargePlanRule, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class RoundingRollingDischargePlanRuleAdjuster: RollingDischargePlanRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingDischargePlanRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingDischargePlanRuleAdjuster: RollingDischargePlanRuleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingDischargePlanRule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling discharge plan rule steps in order and keeps a trace of each.
    final class RollingDischargePlanRuleEngine {
        var steps: [any RollingDischargePlanRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDischargePlanRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingDischargePlanRule) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingDischargePlanRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingDischargePlanRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingDischargePlanRuleEngine() -> RollingDischargePlanRuleEngine {
        return RollingDischargePlanRuleEngine(
            steps: [
                PercentRollingDischargePlanRuleAdjuster(percent: 21.3),
                MinimumRollingDischargePlanRuleAdjuster(minimum: 16.7),
                RollingDischargePlanRuleUpdatedAtOffsetAdjuster(weight: 0.37),
                RoundingRollingDischargePlanRuleAdjuster(step: 0.25),
                TieredRollingDischargePlanRuleAdjuster(bounds: [1877.0, 1963.0, 3273.0], rates: [1.16, 0.98, 1.09]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 54917.6
        )
    }
}
