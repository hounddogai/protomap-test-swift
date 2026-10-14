import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling cleaning entry must pass. Check returns its problems, or none.
    protocol RollingCleaningEntryRule {
        func check(_ item: RollingCleaningEntry) -> [String]
    }

    final class RollingCleaningEntryRequiredLabelRule: RollingCleaningEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCleaningEntry) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCleaningEntryRequiredCategoryRule: RollingCleaningEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCleaningEntry) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCleaningEntryCodePrefixRule: RollingCleaningEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingCleaningEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingCleaningEntryCodeLengthRule: RollingCleaningEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCleaningEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingCleaningEntryUpdatedAtRangeRule: RollingCleaningEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCleaningEntry) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCleaningEntryPayerLengthRule: RollingCleaningEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingCleaningEntry) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling cleaning entry.
    final class RollingCleaningEntryValidator {
        var rules: [any RollingCleaningEntryRule]

        init(rules: [any RollingCleaningEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCleaningEntry) -> [String] {
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

        func requireValid(_ item: RollingCleaningEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCleaningEntry]) -> [String: [String]] {
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

    static func defaultRollingCleaningEntryValidator() -> RollingCleaningEntryValidator {
        return RollingCleaningEntryValidator(
            rules: [
                RollingCleaningEntryRequiredLabelRule(message: "rolling cleaning entry needs a value"),
                RollingCleaningEntryRequiredCategoryRule(message: "rolling cleaning entry needs a value"),
                RollingCleaningEntryCodePrefixRule(prefix: "X"),
                RollingCleaningEntryCodeLengthRule(maxLength: 1000),
                RollingCleaningEntryUpdatedAtRangeRule(min: 16, max: 16),
                RollingCleaningEntryPayerLengthRule(maxLength: 86400),
            ]
        )
    }
}
