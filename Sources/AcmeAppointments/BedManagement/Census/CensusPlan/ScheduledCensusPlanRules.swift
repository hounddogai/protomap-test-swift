import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a scheduled census plan must pass. Check returns its problems, or none.
    protocol ScheduledCensusPlanRule {
        func check(_ item: ScheduledCensusPlan) -> [String]
    }

    final class ScheduledCensusPlanRequiredCodeRule: ScheduledCensusPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCensusPlanCodeLengthRule: ScheduledCensusPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCensusPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCensusPlanTitleLengthRule: ScheduledCensusPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCensusPlan) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCensusPlanRequiredTitleRule: ScheduledCensusPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCensusPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled census plan.
    final class ScheduledCensusPlanValidator {
        var rules: [any ScheduledCensusPlanRule]

        init(rules: [any ScheduledCensusPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCensusPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledCensusPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCensusPlan]) -> [String: [String]] {
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

    static func defaultScheduledCensusPlanValidator() -> ScheduledCensusPlanValidator {
        return ScheduledCensusPlanValidator(
            rules: [
                ScheduledCensusPlanRequiredCodeRule(message: "scheduled census plan needs an entry"),
                ScheduledCensusPlanCodeLengthRule(maxLength: 16),
                ScheduledCensusPlanTitleLengthRule(maxLength: 120),
                ScheduledCensusPlanRequiredTitleRule(message: "scheduled census plan needs a value"),
            ]
        )
    }
}
