import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a goal record must pass. Check returns its problems, or none.
    protocol GoalRecordRule {
        func check(_ item: GoalRecord) -> [String]
    }

    final class GoalRecordRequiredSegmentRule: GoalRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalRecord) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GoalRecordTitleLengthRule: GoalRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GoalRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GoalRecordRequiredSummaryRule: GoalRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GoalRecord) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a goal record.
    final class GoalRecordValidator {
        var rules: [any GoalRecordRule]

        init(rules: [any GoalRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: GoalRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: GoalRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GoalRecord]) -> [String: [String]] {
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

    static func defaultGoalRecordValidator() -> GoalRecordValidator {
        return GoalRecordValidator(
            rules: [
                GoalRecordRequiredSegmentRule(message: "goal record needs a value"),
                GoalRecordTitleLengthRule(maxLength: 3600),
                GoalRecordRequiredSummaryRule(message: "goal record needs a value"),
            ]
        )
    }
}
