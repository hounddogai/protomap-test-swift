import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement target must pass. Check returns its problems, or none.
    protocol StatementTargetRule {
        func check(_ item: StatementTarget) -> [String]
    }

    final class StatementTargetCodePrefixRule: StatementTargetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StatementTarget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StatementTargetRequiredPhoneRule: StatementTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementTarget) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementTargetNameLengthRule: StatementTargetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementTarget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a statement target.
    final class StatementTargetValidator {
        var rules: [any StatementTargetRule]

        init(rules: [any StatementTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementTarget) -> [String] {
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

        func requireValid(_ item: StatementTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementTarget]) -> [String: [String]] {
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

    static func defaultStatementTargetValidator() -> StatementTargetValidator {
        return StatementTargetValidator(
            rules: [
                StatementTargetCodePrefixRule(prefix: "Q"),
                StatementTargetRequiredPhoneRule(message: "statement target needs this field"),
                StatementTargetNameLengthRule(maxLength: 80),
            ]
        )
    }
}
