import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning plan must pass. Check returns its problems, or none.
    protocol CleaningPlanRule {
        func check(_ item: CleaningPlan) -> [String]
    }

    final class CleaningPlanLimitRangeRule: CleaningPlanRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningPlan) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningPlanRequiredTitleRule: CleaningPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningPlan) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningPlanCodeLengthRule: CleaningPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CleaningPlanCodePrefixRule: CleaningPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning plan.
    final class CleaningPlanValidator {
        var rules: [any CleaningPlanRule]

        init(rules: [any CleaningPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningPlan) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningPlan]) -> [String: [String]] {
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

    static func defaultCleaningPlanValidator() -> CleaningPlanValidator {
        return CleaningPlanValidator(
            rules: [
                CleaningPlanLimitRangeRule(min: 16, max: 3600),
                CleaningPlanRequiredTitleRule(message: "cleaning plan needs this field"),
                CleaningPlanCodeLengthRule(maxLength: 80),
                CleaningPlanCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
