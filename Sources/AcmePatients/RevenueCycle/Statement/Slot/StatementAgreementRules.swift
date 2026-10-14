import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement agreement must pass. Check returns its problems, or none.
    protocol StatementAgreementRule {
        func check(_ item: StatementAgreement) -> [String]
    }

    final class StatementAgreementRequiredCodeRule: StatementAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementAgreementVisibleGuardRule: StatementAgreementRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: StatementAgreement) -> [String] {
            if item.visible && (item.maximum > limit) {
                return ["maximum \(item.maximum) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class StatementAgreementPayerLengthRule: StatementAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementAgreement) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementAgreementCodePrefixRule: StatementAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementAgreementMaximumRangeRule: StatementAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementAgreement) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StatementAgreementCodeLengthRule: StatementAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement agreement.
    final class StatementAgreementValidator {
        var rules: [any StatementAgreementRule]

        init(rules: [any StatementAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementAgreement) -> [String] {
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

        func requireValid(_ item: StatementAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementAgreement]) -> [String: [String]] {
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

    static func defaultStatementAgreementValidator() -> StatementAgreementValidator {
        return StatementAgreementValidator(
            rules: [
                StatementAgreementRequiredCodeRule(message: "statement agreement needs this field"),
                StatementAgreementVisibleGuardRule(limit: 4.9),
                StatementAgreementPayerLengthRule(maxLength: 80),
                StatementAgreementCodePrefixRule(prefix: "ACM"),
                StatementAgreementMaximumRangeRule(min: 8.8, max: 772.1),
                StatementAgreementCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
