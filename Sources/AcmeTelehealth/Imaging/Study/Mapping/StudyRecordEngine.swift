import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study record calculation.
    protocol StudyRecordModifier {
        func describe() -> String
        func adjust(_ item: StudyRecord, value: Double) -> Double
    }

    final class RoundingStudyRecordAdjuster: StudyRecordModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CategoryStudyRecordAdjuster: StudyRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: StudyRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStudyRecordAdjuster: StudyRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStudyRecordAdjuster: StudyRecordModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStudyRecordAdjuster: StudyRecordModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStudyRecordAdjuster: StudyRecordModifier {
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

        func adjust(_ item: StudyRecord, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study record steps in order and keeps a trace of each.
    final class StudyRecordEngine {
        var steps: [any StudyRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StudyRecord) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyRecordModifier = steps[index]
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

        func evaluateAll(_ items: [StudyRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStudyRecordEngine(_ flags: Kit.Flags.Registry) -> StudyRecordEngine {
        return StudyRecordEngine(
            steps: [
                RoundingStudyRecordAdjuster(step: 0.5),
                CategoryStudyRecordAdjuster(factors: ["south": 1.06, "central": 1.03]),
                MinimumStudyRecordAdjuster(minimum: 3.2),
                PercentStudyRecordAdjuster(percent: 8.5),
                CapStudyRecordAdjuster(cap: 24306.0),
                FlaggedStudyRecordAdjuster(flags: flags, flag: "study-record-regional", percent: 7.2),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 78652.1
        )
    }
}
