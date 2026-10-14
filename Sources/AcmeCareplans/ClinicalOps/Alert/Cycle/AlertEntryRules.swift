import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert entry must pass. Check returns its problems, or none.
    protocol AlertEntryRule {
        func check(_ item: AlertEntry) -> [String]
    }

    final class AlertEntryBudgetRangeRule: AlertEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertEntry) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AlertEntryRequiredTitleRule: AlertEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertEntryAcuityRangeRule: AlertEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AlertEntry) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert entry.
    final class AlertEntryValidator {
        var rules: [any AlertEntryRule]

        init(rules: [any AlertEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AlertEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertEntry]) -> [String: [String]] {
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

    static func defaultAlertEntryValidator() -> AlertEntryValidator {
        return AlertEntryValidator(
            rules: [
                AlertEntryBudgetRangeRule(min: 8.1, max: 1980.3),
                AlertEntryRequiredTitleRule(message: "alert entry needs a value"),
                AlertEntryAcuityRangeRule(min: 255, max: 255),
            ]
        )
    }
}
