import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score target calculation.
    protocol RiskScoreTargetModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreTarget, value: Double) -> Double
    }

    final class CapRiskScoreTargetAdjuster: RiskScoreTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RiskScoreTargetDiscountOffsetAdjuster: RiskScoreTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: RiskScoreTarget, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingRiskScoreTargetAdjuster: RiskScoreTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRiskScoreTargetAdjuster: RiskScoreTargetModifier {
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

        func adjust(_ item: RiskScoreTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the risk score target steps in order and keeps a trace of each.
    final class RiskScoreTargetEngine {
        var steps: [any RiskScoreTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RiskScoreTarget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreTargetModifier = steps[index]
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

        func evaluateAll(_ items: [RiskScoreTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRiskScoreTargetEngine(_ flags: Kit.Flags.Registry) -> RiskScoreTargetEngine {
        return RiskScoreTargetEngine(
            steps: [
                CapRiskScoreTargetAdjuster(cap: 41465.0),
                RiskScoreTargetDiscountOffsetAdjuster(weight: 1.74),
                RoundingRiskScoreTargetAdjuster(step: 0.1),
                FlaggedRiskScoreTargetAdjuster(flags: flags, flag: "risk-score-target-manual", percent: 1.5),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 9419.2
        )
    }
}
