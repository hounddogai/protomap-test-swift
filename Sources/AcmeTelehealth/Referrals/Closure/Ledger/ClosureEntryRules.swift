import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure entry must pass. Check returns its problems, or none.
    protocol ClosureEntryRule {
        func check(_ item: ClosureEntry) -> [String]
    }

    final class ClosureEntryRequiredCategoryRule: ClosureEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureEntry) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureEntryCodePrefixRule: ClosureEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClosureEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClosureEntryFacilityLengthRule: ClosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureEntry) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClosureEntryCodeLengthRule: ClosureEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClosureEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a closure entry.
    final class ClosureEntryValidator {
        var rules: [any ClosureEntryRule]

        init(rules: [any ClosureEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureEntry) -> [String] {
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

        func requireValid(_ item: ClosureEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureEntry]) -> [String: [String]] {
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

    static func defaultClosureEntryValidator() -> ClosureEntryValidator {
        return ClosureEntryValidator(
            rules: [
                ClosureEntryRequiredCategoryRule(message: "closure entry needs an entry"),
                ClosureEntryCodePrefixRule(prefix: "REF"),
                ClosureEntryFacilityLengthRule(maxLength: 16),
                ClosureEntryCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
