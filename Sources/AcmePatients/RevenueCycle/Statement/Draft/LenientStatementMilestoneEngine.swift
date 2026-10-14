import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient statement milestone calculation.
    protocol LenientStatementMilestoneModifier {
        func describe() -> String
        func adjust(_ item: LenientStatementMilestone, value: Double) -> Double
    }

    final class TieredLenientStatementMilestoneAdjuster: LenientStatementMilestoneModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientStatementMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientStatementMilestoneAdjuster: LenientStatementMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientStatementMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientStatementMilestoneAdjuster: LenientStatementMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientStatementMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLenientStatementMilestoneAdjuster: LenientStatementMilestoneModifier {
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

        func adjust(_ item: LenientStatementMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientStatementMilestoneAdjuster: LenientStatementMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientStatementMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient statement milestone steps in order and keeps a trace of each.
    final class LenientStatementMilestoneEngine {
        var steps: [any LenientStatementMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientStatementMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientStatementMilestone) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientStatementMilestoneModifier = steps[index]
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

        func evaluateAll(_ items: [LenientStatementMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientStatementMilestoneEngine(_ flags: Kit.Flags.Registry) -> LenientStatementMilestoneEngine {
        return LenientStatementMilestoneEngine(
            steps: [
                TieredLenientStatementMilestoneAdjuster(bounds: [2992.0, 6080.0, 6713.0], rates: [1.03, 0.93, 1.0]),
                MinimumLenientStatementMilestoneAdjuster(minimum: 19.3),
                PercentLenientStatementMilestoneAdjuster(percent: 4.6),
                FlaggedLenientStatementMilestoneAdjuster(
                    flags: flags,
                    flag: "lenient-statement-milestone-weighted",
                    percent: -1.5
                ),
                RoundingLenientStatementMilestoneAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 54788.1
        )
    }
}
