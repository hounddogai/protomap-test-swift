import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive goal baseline calculation.
    protocol AdaptiveGoalBaselineModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveGoalBaseline, value: Double) -> Double
    }

    final class FlaggedAdaptiveGoalBaselineAdjuster: AdaptiveGoalBaselineModifier {
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

        func adjust(_ item: AdaptiveGoalBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptiveGoalBaselineAdjuster: AdaptiveGoalBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveGoalBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AdaptiveGoalBaselineDiscountOffsetAdjuster: AdaptiveGoalBaselineModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: AdaptiveGoalBaseline, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the adaptive goal baseline steps in order and keeps a trace of each.
    final class AdaptiveGoalBaselineEngine {
        var steps: [any AdaptiveGoalBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveGoalBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveGoalBaseline) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [AdaptiveGoalBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveGoalBaselineEngine(_ flags: Kit.Flags.Registry) -> AdaptiveGoalBaselineEngine {
        return AdaptiveGoalBaselineEngine(
            steps: [
                FlaggedAdaptiveGoalBaselineAdjuster(
                    flags: flags,
                    flag: "adaptive-goal-baseline-default",
                    percent: 6.1
                ),
                CapAdaptiveGoalBaselineAdjuster(cap: 17712.0),
                AdaptiveGoalBaselineDiscountOffsetAdjuster(weight: 1.45),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 74580.8
        )
    }
}
