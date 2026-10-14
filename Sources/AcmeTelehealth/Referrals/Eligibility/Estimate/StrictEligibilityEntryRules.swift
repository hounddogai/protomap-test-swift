import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a strict eligibility entry must pass. Check returns its problems, or none.
    protocol StrictEligibilityEntryRule {
        func check(_ item: StrictEligibilityEntry) -> [String]
    }

    final class StrictEligibilityEntryRequiredTitleRule: StrictEligibilityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictEligibilityEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictEligibilityEntryTitleLengthRule: StrictEligibilityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictEligibilityEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictEligibilityEntryCodeLengthRule: StrictEligibilityEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictEligibilityEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictEligibilityEntryRequiredSummaryRule: StrictEligibilityEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictEligibilityEntry) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict eligibility entry.
    final class StrictEligibilityEntryValidator {
        var rules: [any StrictEligibilityEntryRule]

        init(rules: [any StrictEligibilityEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictEligibilityEntry) -> [String] {
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

        func requireValid(_ item: StrictEligibilityEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictEligibilityEntry]) -> [String: [String]] {
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

    static func defaultStrictEligibilityEntryValidator() -> StrictEligibilityEntryValidator {
        return StrictEligibilityEntryValidator(
            rules: [
                StrictEligibilityEntryRequiredTitleRule(message: "strict eligibility entry needs an entry"),
                StrictEligibilityEntryTitleLengthRule(maxLength: 255),
                StrictEligibilityEntryCodeLengthRule(maxLength: 64),
                StrictEligibilityEntryRequiredSummaryRule(message: "strict eligibility entry needs an entry"),
            ]
        )
    }
}
