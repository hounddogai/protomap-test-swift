import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert baseline must pass. Check returns its problems, or none.
    protocol AlertBaselineRule {
        func check(_ item: AlertBaseline) -> [String]
    }

    final class AlertBaselineRequiredDescriptionRule: AlertBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBaseline) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertBaselineTitleLengthRule: AlertBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertBaseline) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertBaselineCodeLengthRule: AlertBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertBaselineDescriptionLengthRule: AlertBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertBaseline) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AlertBaselineRequiredCodeRule: AlertBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertBaseline) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a alert baseline.
    final class AlertBaselineValidator {
        var rules: [any AlertBaselineRule]

        init(rules: [any AlertBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertBaseline) -> [String] {
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

        func requireValid(_ item: AlertBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertBaseline]) -> [String: [String]] {
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

    static func defaultAlertBaselineValidator() -> AlertBaselineValidator {
        return AlertBaselineValidator(
            rules: [
                AlertBaselineRequiredDescriptionRule(message: "alert baseline needs a value"),
                AlertBaselineTitleLengthRule(maxLength: 1000),
                AlertBaselineCodeLengthRule(maxLength: 3600),
                AlertBaselineDescriptionLengthRule(maxLength: 120),
                AlertBaselineRequiredCodeRule(message: "alert baseline needs an entry"),
            ]
        )
    }
}
