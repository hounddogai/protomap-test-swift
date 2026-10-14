import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict isolation schedule must pass. Check returns its problems, or none.
    protocol StrictIsolationScheduleRule {
        func check(_ item: StrictIsolationSchedule) -> [String]
    }

    final class StrictIsolationScheduleLabelLengthRule: StrictIsolationScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictIsolationSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictIsolationScheduleScoreRangeRule: StrictIsolationScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictIsolationSchedule) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictIsolationScheduleRequiredLabelRule: StrictIsolationScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictIsolationSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictIsolationScheduleRequiredTitleRule: StrictIsolationScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictIsolationSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict isolation schedule.
    final class StrictIsolationScheduleValidator {
        var rules: [any StrictIsolationScheduleRule]

        init(rules: [any StrictIsolationScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictIsolationSchedule) -> [String] {
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

        func requireValid(_ item: StrictIsolationSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictIsolationSchedule]) -> [String: [String]] {
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

    static func defaultStrictIsolationScheduleValidator() -> StrictIsolationScheduleValidator {
        return StrictIsolationScheduleValidator(
            rules: [
                StrictIsolationScheduleLabelLengthRule(maxLength: 1000),
                StrictIsolationScheduleScoreRangeRule(min: 8.4, max: 4150.7),
                StrictIsolationScheduleRequiredLabelRule(message: "strict isolation schedule needs an entry"),
                StrictIsolationScheduleRequiredTitleRule(message: "strict isolation schedule needs an entry"),
            ]
        )
    }
}
