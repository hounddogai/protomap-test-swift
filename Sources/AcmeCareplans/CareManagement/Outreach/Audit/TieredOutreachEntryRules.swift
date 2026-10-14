import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a tiered outreach entry must pass. Check returns its problems, or none.
    protocol TieredOutreachEntryRule {
        func check(_ item: TieredOutreachEntry) -> [String]
    }

    final class TieredOutreachEntryCodeLengthRule: TieredOutreachEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredOutreachEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredOutreachEntryCodePrefixRule: TieredOutreachEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: TieredOutreachEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class TieredOutreachEntryRequiredNameRule: TieredOutreachEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredOutreachEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a tiered outreach entry.
    final class TieredOutreachEntryValidator {
        var rules: [any TieredOutreachEntryRule]

        init(rules: [any TieredOutreachEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredOutreachEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredOutreachEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredOutreachEntry]) -> [String: [String]] {
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

    static func defaultTieredOutreachEntryValidator() -> TieredOutreachEntryValidator {
        return TieredOutreachEntryValidator(
            rules: [
                TieredOutreachEntryCodeLengthRule(maxLength: 3600),
                TieredOutreachEntryCodePrefixRule(prefix: "ACM"),
                TieredOutreachEntryRequiredNameRule(message: "tiered outreach entry needs an entry"),
            ]
        )
    }
}
