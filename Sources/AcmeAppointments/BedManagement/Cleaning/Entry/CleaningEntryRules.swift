import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning entry must pass. Check returns its problems, or none.
    protocol CleaningEntryRule {
        func check(_ item: CleaningEntry) -> [String]
    }

    final class CleaningEntryAllowedCodeRule: CleaningEntryRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningEntry) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class CleaningEntryBudgetRangeRule: CleaningEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningEntry) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CleaningEntryRequiredCategoryRule: CleaningEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningEntry) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningEntryFloorValueRangeRule: CleaningEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CleaningEntry) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CleaningEntryCodePrefixRule: CleaningEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CleaningEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning entry.
    final class CleaningEntryValidator {
        var rules: [any CleaningEntryRule]

        init(rules: [any CleaningEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningEntry]) -> [String: [String]] {
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

    static func defaultCleaningEntryValidator() -> CleaningEntryValidator {
        return CleaningEntryValidator(
            rules: [
                CleaningEntryAllowedCodeRule(allowed: []),
                CleaningEntryBudgetRangeRule(min: 2.3, max: 436.4),
                CleaningEntryRequiredCategoryRule(message: "cleaning entry needs a value"),
                CleaningEntryFloorValueRangeRule(min: 3.3, max: 3062.8),
                CleaningEntryCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
