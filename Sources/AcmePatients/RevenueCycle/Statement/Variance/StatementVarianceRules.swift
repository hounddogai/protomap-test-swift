import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement variance must pass. Check returns its problems, or none.
    protocol StatementVarianceRule {
        func check(_ item: StatementVariance) -> [String]
    }

    final class StatementVarianceRequiredTimezoneRule: StatementVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementVariance) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementVarianceCodeLengthRule: StatementVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementVarianceAllowedLabelRule: StatementVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: StatementVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class StatementVarianceLabelLengthRule: StatementVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementVariance) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement variance.
    final class StatementVarianceValidator {
        var rules: [any StatementVarianceRule]

        init(rules: [any StatementVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementVariance) -> [String] {
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

        func requireValid(_ item: StatementVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementVariance]) -> [String: [String]] {
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

    static func defaultStatementVarianceValidator() -> StatementVarianceValidator {
        return StatementVarianceValidator(
            rules: [
                StatementVarianceRequiredTimezoneRule(message: "statement variance needs an entry"),
                StatementVarianceCodeLengthRule(maxLength: 120),
                StatementVarianceAllowedLabelRule(allowed: []),
                StatementVarianceLabelLengthRule(maxLength: 16),
            ]
        )
    }
}
