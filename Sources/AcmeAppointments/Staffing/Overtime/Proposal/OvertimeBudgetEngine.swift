import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime budget calculation.
    protocol OvertimeBudgetFactor {
        func describe() -> String
        func adjust(_ item: OvertimeBudget, value: Double) -> Double
    }

    final class FlaggedOvertimeBudgetAdjuster: OvertimeBudgetFactor {
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

        func adjust(_ item: OvertimeBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class OvertimeBudgetDurationMinutesOffsetAdjuster: OvertimeBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: OvertimeBudget, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class ChannelOvertimeBudgetAdjuster: OvertimeBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: OvertimeBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the overtime budget steps in order and keeps a trace of each.
    final class OvertimeBudgetEngine {
        var steps: [any OvertimeBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimeBudget) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeBudgetFactor = steps[index]
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

        func evaluateAll(_ items: [OvertimeBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimeBudgetEngine(_ flags: Kit.Flags.Registry) -> OvertimeBudgetEngine {
        return OvertimeBudgetEngine(
            steps: [
                FlaggedOvertimeBudgetAdjuster(flags: flags, flag: "overtime-budget-manual", percent: 7.6),
                OvertimeBudgetDurationMinutesOffsetAdjuster(weight: 1.03),
                ChannelOvertimeBudgetAdjuster(factors: ["south": 0.91, "central": 0.98, "north": 0.94]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 71636.1
        )
    }
}
