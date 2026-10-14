import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a study summary must pass. Check returns its problems, or none.
    protocol StudySummaryRule {
        func check(_ item: StudySummary) -> [String]
    }

    final class StudySummaryRequiredTitleRule: StudySummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StudySummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StudySummaryChannelLengthRule: StudySummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StudySummary) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StudySummaryCapacityRangeRule: StudySummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StudySummary) -> [String] {
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

    /// Runs every rule of a study summary.
    final class StudySummaryValidator {
        var rules: [any StudySummaryRule]

        init(rules: [any StudySummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: StudySummary) -> [String] {
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

        func requireValid(_ item: StudySummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StudySummary]) -> [String: [String]] {
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

    static func defaultStudySummaryValidator() -> StudySummaryValidator {
        return StudySummaryValidator(
            rules: [
                StudySummaryRequiredTitleRule(message: "study summary needs a value"),
                StudySummaryChannelLengthRule(maxLength: 1000),
                StudySummaryCapacityRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
