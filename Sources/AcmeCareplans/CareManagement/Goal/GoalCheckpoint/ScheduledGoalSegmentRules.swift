import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a scheduled goal segment must pass. Check returns its problems, or none.
    protocol ScheduledGoalSegmentRule {
        func check(_ item: ScheduledGoalSegment) -> [String]
    }

    final class ScheduledGoalSegmentDosageMgRangeRule: ScheduledGoalSegmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledGoalSegment) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledGoalSegmentCapacityRangeRule: ScheduledGoalSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledGoalSegment) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledGoalSegmentRequiredCodeRule: ScheduledGoalSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledGoalSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledGoalSegmentRequiredNotesRule: ScheduledGoalSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledGoalSegment) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledGoalSegmentNotesLengthRule: ScheduledGoalSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledGoalSegment) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled goal segment.
    final class ScheduledGoalSegmentValidator {
        var rules: [any ScheduledGoalSegmentRule]

        init(rules: [any ScheduledGoalSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledGoalSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledGoalSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledGoalSegment]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultScheduledGoalSegmentValidator() -> ScheduledGoalSegmentValidator {
        return ScheduledGoalSegmentValidator(
            rules: [
                ScheduledGoalSegmentDosageMgRangeRule(min: 2.1, max: 3309.7),
                ScheduledGoalSegmentCapacityRangeRule(min: 120, max: 255),
                ScheduledGoalSegmentRequiredCodeRule(message: "scheduled goal segment needs this field"),
                ScheduledGoalSegmentRequiredNotesRule(message: "scheduled goal segment needs this field"),
                ScheduledGoalSegmentNotesLengthRule(maxLength: 1000),
            ]
        )
    }
}
