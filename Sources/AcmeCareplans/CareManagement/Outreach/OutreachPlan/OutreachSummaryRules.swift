import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a outreach summary must pass. Check returns its problems, or none.
    protocol OutreachSummaryRule {
        func check(_ item: OutreachSummary) -> [String]
    }

    final class OutreachSummaryCodePrefixRule: OutreachSummaryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: OutreachSummary) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class OutreachSummarySpecialtyLengthRule: OutreachSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachSummary) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachSummaryCodeLengthRule: OutreachSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OutreachSummary) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OutreachSummaryRequiredCodeRule: OutreachSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OutreachSummaryRequiredTitleRule: OutreachSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OutreachSummary) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a outreach summary.
    final class OutreachSummaryValidator {
        var rules: [any OutreachSummaryRule]

        init(rules: [any OutreachSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: OutreachSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OutreachSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OutreachSummary]) -> [String: [String]] {
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

    static func defaultOutreachSummaryValidator() -> OutreachSummaryValidator {
        return OutreachSummaryValidator(
            rules: [
                OutreachSummaryCodePrefixRule(prefix: "Q"),
                OutreachSummarySpecialtyLengthRule(maxLength: 64),
                OutreachSummaryCodeLengthRule(maxLength: 16),
                OutreachSummaryRequiredCodeRule(message: "outreach summary needs this field"),
                OutreachSummaryRequiredTitleRule(message: "outreach summary needs an entry"),
            ]
        )
    }
}
