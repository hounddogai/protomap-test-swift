import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a alert rollup must pass. Check returns its problems, or none.
    protocol AlertRollupRule {
        func check(_ item: AlertRollup) -> [String]
    }

    final class AlertRollupRequiredDescriptionRule: AlertRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertRollup) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertRollupRequiredTitleRule: AlertRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertRollup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertRollupRequiredCodeRule: AlertRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AlertRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AlertRollupSourceLengthRule: AlertRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AlertRollup) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a alert rollup.
    final class AlertRollupValidator {
        var rules: [any AlertRollupRule]

        init(rules: [any AlertRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: AlertRollup) -> [String] {
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

        func requireValid(_ item: AlertRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AlertRollup]) -> [String: [String]] {
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

    static func defaultAlertRollupValidator() -> AlertRollupValidator {
        return AlertRollupValidator(
            rules: [
                AlertRollupRequiredDescriptionRule(message: "alert rollup needs an entry"),
                AlertRollupRequiredTitleRule(message: "alert rollup needs this field"),
                AlertRollupRequiredCodeRule(message: "alert rollup needs this field"),
                AlertRollupSourceLengthRule(maxLength: 86400),
            ]
        )
    }
}
