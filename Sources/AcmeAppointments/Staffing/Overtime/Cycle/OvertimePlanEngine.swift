import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime plan calculation.
    protocol OvertimePlanStep {
        func describe() -> String
        func adjust(_ item: OvertimePlan, value: Double) -> Double
    }

    final class FlaggedOvertimePlanAdjuster: OvertimePlanStep {
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

        func adjust(_ item: OvertimePlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumOvertimePlanAdjuster: OvertimePlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimePlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentOvertimePlanAdjuster: OvertimePlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimePlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleOvertimePlanAdjuster: OvertimePlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: OvertimePlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the overtime plan steps in order and keeps a trace of each.
    final class OvertimePlanEngine {
        var steps: [any OvertimePlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimePlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimePlan) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimePlanStep = steps[index]
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

        func evaluateAll(_ items: [OvertimePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimePlanEngine(_ flags: Kit.Flags.Registry) -> OvertimePlanEngine {
        return OvertimePlanEngine(
            steps: [
                FlaggedOvertimePlanAdjuster(flags: flags, flag: "overtime-plan-global", percent: -7.4),
                MinimumOvertimePlanAdjuster(minimum: 20.7),
                PercentOvertimePlanAdjuster(percent: 1.7),
                TitleOvertimePlanAdjuster(factors: ["west": 0.74]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 20486.5
        )
    }
}
