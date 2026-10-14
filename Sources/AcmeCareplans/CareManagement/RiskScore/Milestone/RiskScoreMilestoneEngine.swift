import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score milestone calculation.
    protocol RiskScoreMilestoneStep {
        func describe() -> String
        func adjust(_ item: RiskScoreMilestone, value: Double) -> Double
    }

    final class TieredRiskScoreMilestoneAdjuster: RiskScoreMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRiskScoreMilestoneAdjuster: RiskScoreMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitRiskScoreMilestoneAdjuster: RiskScoreMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RiskScoreMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRiskScoreMilestoneAdjuster: RiskScoreMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRiskScoreMilestoneAdjuster: RiskScoreMilestoneStep {
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

        func adjust(_ item: RiskScoreMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRiskScoreMilestoneAdjuster: RiskScoreMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score milestone steps in order and keeps a trace of each.
    final class RiskScoreMilestoneEngine {
        var steps: [any RiskScoreMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RiskScoreMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreMilestoneStep = steps[index]
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

        func evaluateAll(_ items: [RiskScoreMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRiskScoreMilestoneEngine(_ flags: Kit.Flags.Registry) -> RiskScoreMilestoneEngine {
        return RiskScoreMilestoneEngine(
            steps: [
                TieredRiskScoreMilestoneAdjuster(
                    bounds: [1829.0, 2293.0, 4571.0, 8831.0],
                    rates: [0.85, 1.09, 0.84, 1.19]
                ),
                RoundingRiskScoreMilestoneAdjuster(step: 0.5),
                UnitRiskScoreMilestoneAdjuster(factors: ["south": 0.86]),
                MinimumRiskScoreMilestoneAdjuster(minimum: 36.3),
                FlaggedRiskScoreMilestoneAdjuster(flags: flags, flag: "risk-score-milestone-primary", percent: -4.3),
                PercentRiskScoreMilestoneAdjuster(percent: -6.6),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 91263.4
        )
    }
}
