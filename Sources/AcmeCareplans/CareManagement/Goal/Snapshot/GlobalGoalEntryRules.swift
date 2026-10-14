import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a global goal entry must pass. Check returns its problems, or none.
    protocol GlobalGoalEntryRule {
        func check(_ item: GlobalGoalEntry) -> [String]
    }

    final class GlobalGoalEntryContactEmailLengthRule: GlobalGoalEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalGoalEntry) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalGoalEntryWindowDaysRangeRule: GlobalGoalEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalGoalEntry) -> [String] {
            let value = item.windowDays
            var problems: [String] = []
            if value < min {
                problems.append("window days \(value) is below \(min)")
            }
            if value > max {
                problems.append("window days \(value) is above \(max)")
            }
            return problems
        }
    }

    final class GlobalGoalEntryCodePrefixRule: GlobalGoalEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalGoalEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalGoalEntryRequiredLabelRule: GlobalGoalEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalGoalEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a global goal entry.
    final class GlobalGoalEntryValidator {
        var rules: [any GlobalGoalEntryRule]

        init(rules: [any GlobalGoalEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalGoalEntry) -> [String] {
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

        func requireValid(_ item: GlobalGoalEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalGoalEntry]) -> [String: [String]] {
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

    static func defaultGlobalGoalEntryValidator() -> GlobalGoalEntryValidator {
        return GlobalGoalEntryValidator(
            rules: [
                GlobalGoalEntryContactEmailLengthRule(maxLength: 1000),
                GlobalGoalEntryWindowDaysRangeRule(min: 80, max: 86400),
                GlobalGoalEntryCodePrefixRule(prefix: "REF"),
                GlobalGoalEntryRequiredLabelRule(message: "global goal entry needs an entry"),
            ]
        )
    }
}
