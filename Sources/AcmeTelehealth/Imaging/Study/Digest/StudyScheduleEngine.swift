import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study schedule calculation.
    protocol StudyScheduleStep {
        func describe() -> String
        func adjust(_ item: StudySchedule, value: Double) -> Double
    }

    final class MinimumStudyScheduleAdjuster: StudyScheduleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStudyScheduleAdjuster: StudyScheduleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudySchedule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStudyScheduleAdjuster: StudyScheduleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudySchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameStudyScheduleAdjuster: StudyScheduleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StudySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStudyScheduleAdjuster: StudyScheduleStep {
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

        func adjust(_ item: StudySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study schedule steps in order and keeps a trace of each.
    final class StudyScheduleEngine {
        var steps: [any StudyScheduleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyScheduleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StudySchedule) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyScheduleStep = steps[index]
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

        func evaluateAll(_ items: [StudySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStudyScheduleEngine(_ flags: Kit.Flags.Registry) -> StudyScheduleEngine {
        return StudyScheduleEngine(
            steps: [
                MinimumStudyScheduleAdjuster(minimum: 17.2),
                PercentStudyScheduleAdjuster(percent: 6.6),
                RoundingStudyScheduleAdjuster(step: 0.1),
                NameStudyScheduleAdjuster(factors: ["east": 1.1, "west": 0.75]),
                FlaggedStudyScheduleAdjuster(flags: flags, flag: "study-schedule-scheduled", percent: -6.9),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 78737.0
        )
    }
}
