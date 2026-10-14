import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the scheduled bed board rule calculation.
    protocol ScheduledBedBoardRuleStep {
        func describe() -> String
        func adjust(_ item: ScheduledBedBoardRule, value: Double) -> Double
    }

    final class FlaggedScheduledBedBoardRuleAdjuster: ScheduledBedBoardRuleStep {
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

        func adjust(_ item: ScheduledBedBoardRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledBedBoardRuleAdjuster: ScheduledBedBoardRuleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledBedBoardRule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingScheduledBedBoardRuleAdjuster: ScheduledBedBoardRuleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledBedBoardRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentScheduledBedBoardRuleAdjuster: ScheduledBedBoardRuleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledBedBoardRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameScheduledBedBoardRuleAdjuster: ScheduledBedBoardRuleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ScheduledBedBoardRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled bed board rule steps in order and keeps a trace of each.
    final class ScheduledBedBoardRuleEngine {
        var steps: [any ScheduledBedBoardRuleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledBedBoardRuleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledBedBoardRule) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledBedBoardRuleStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledBedBoardRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledBedBoardRuleEngine(_ flags: Kit.Flags.Registry) -> ScheduledBedBoardRuleEngine {
        return ScheduledBedBoardRuleEngine(
            steps: [
                FlaggedScheduledBedBoardRuleAdjuster(
                    flags: flags,
                    flag: "scheduled-bed-board-rule-primary",
                    percent: -4.4
                ),
                MinimumScheduledBedBoardRuleAdjuster(minimum: 8.6),
                RoundingScheduledBedBoardRuleAdjuster(step: 0.1),
                PercentScheduledBedBoardRuleAdjuster(percent: -19.7),
                NameScheduledBedBoardRuleAdjuster(factors: ["east": 1.06, "north": 1.31]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 46492.5
        )
    }
}
