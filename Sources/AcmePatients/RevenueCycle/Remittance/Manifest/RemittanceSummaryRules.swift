import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance summary must pass. Check returns its problems, or none.
    protocol RemittanceSummaryRule {
        func check(_ item: RemittanceSummary) -> [String]
    }

    final class RemittanceSummaryCodeLengthRule: RemittanceSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceSummaryRequiredCodeRule: RemittanceSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceSummaryTimezoneLengthRule: RemittanceSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSummary) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceSummaryCodePrefixRule: RemittanceSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance summary.
    final class RemittanceSummaryValidator {
        var rules: [any RemittanceSummaryRule]

        init(rules: [any RemittanceSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceSummary]) -> [String: [String]] {
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

    static func defaultRemittanceSummaryValidator() -> RemittanceSummaryValidator {
        return RemittanceSummaryValidator(
            rules: [
                RemittanceSummaryCodeLengthRule(maxLength: 120),
                RemittanceSummaryRequiredCodeRule(message: "remittance summary needs this field"),
                RemittanceSummaryTimezoneLengthRule(maxLength: 16),
                RemittanceSummaryCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
