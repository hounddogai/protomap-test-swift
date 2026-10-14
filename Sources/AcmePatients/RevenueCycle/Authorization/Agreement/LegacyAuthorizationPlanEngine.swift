import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy authorization plan calculation.
    protocol LegacyAuthorizationPlanModifier {
        func describe() -> String
        func adjust(_ item: LegacyAuthorizationPlan, value: Double) -> Double
    }

    final class SegmentLegacyAuthorizationPlanAdjuster: LegacyAuthorizationPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: LegacyAuthorizationPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyAuthorizationPlanAdjuster: LegacyAuthorizationPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAuthorizationPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyAuthorizationPlanAdjuster: LegacyAuthorizationPlanModifier {
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

        func adjust(_ item: LegacyAuthorizationPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy authorization plan steps in order and keeps a trace of each.
    final class LegacyAuthorizationPlanEngine {
        var steps: [any LegacyAuthorizationPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAuthorizationPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyAuthorizationPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAuthorizationPlanModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyAuthorizationPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyAuthorizationPlanEngine(_ flags: Kit.Flags.Registry) -> LegacyAuthorizationPlanEngine {
        return LegacyAuthorizationPlanEngine(
            steps: [
                SegmentLegacyAuthorizationPlanAdjuster(factors: ["south": 1.29, "retail": 0.81]),
                RoundingLegacyAuthorizationPlanAdjuster(step: 0.5),
                FlaggedLegacyAuthorizationPlanAdjuster(
                    flags: flags,
                    flag: "legacy-authorization-plan-rolling",
                    percent: -1.0
                ),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 54449.6
        )
    }
}
