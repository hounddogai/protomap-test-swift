import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance summary calculation.
    protocol RemittanceSummaryModifier {
        func describe() -> String
        func adjust(_ item: RemittanceSummary, value: Double) -> Double
    }

    final class PercentRemittanceSummaryAdjuster: RemittanceSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRemittanceSummaryAdjuster: RemittanceSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRemittanceSummaryAdjuster: RemittanceSummaryModifier {
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

        func adjust(_ item: RemittanceSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRemittanceSummaryAdjuster: RemittanceSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RemittanceSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the remittance summary steps in order and keeps a trace of each.
    final class RemittanceSummaryEngine {
        var steps: [any RemittanceSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [RemittanceSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceSummaryEngine(_ flags: Kit.Flags.Registry) -> RemittanceSummaryEngine {
        return RemittanceSummaryEngine(
            steps: [
                PercentRemittanceSummaryAdjuster(percent: 0.3),
                RoundingRemittanceSummaryAdjuster(step: 0.25),
                FlaggedRemittanceSummaryAdjuster(flags: flags, flag: "remittance-summary-tiered", percent: -7.9),
                MinimumRemittanceSummaryAdjuster(minimum: 16.9),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 88274.8
        )
    }
}
