import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff schedule calculation.
    protocol HandoffScheduleFactor {
        func describe() -> String
        func adjust(_ item: HandoffSchedule, value: Double) -> Double
    }

    final class FlaggedHandoffScheduleAdjuster: HandoffScheduleFactor {
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

        func adjust(_ item: HandoffSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumHandoffScheduleAdjuster: HandoffScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitHandoffScheduleAdjuster: HandoffScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: HandoffSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingHandoffScheduleAdjuster: HandoffScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffSchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the handoff schedule steps in order and keeps a trace of each.
    final class HandoffScheduleEngine {
        var steps: [any HandoffScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: HandoffSchedule) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [HandoffSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultHandoffScheduleEngine(_ flags: Kit.Flags.Registry) -> HandoffScheduleEngine {
        return HandoffScheduleEngine(
            steps: [
                FlaggedHandoffScheduleAdjuster(flags: flags, flag: "handoff-schedule-pending", percent: 4.9),
                MinimumHandoffScheduleAdjuster(minimum: 45.9),
                UnitHandoffScheduleAdjuster(factors: ["online": 0.93]),
                RoundingHandoffScheduleAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 31280.3
        )
    }
}
