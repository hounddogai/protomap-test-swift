import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a manual inventory entry must pass. Check returns its problems, or none.
    protocol ManualInventoryEntryRule {
        func check(_ item: ManualInventoryEntry) -> [String]
    }

    final class ManualInventoryEntryRequiredCurrencyRule: ManualInventoryEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventoryEntry) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualInventoryEntryCodePrefixRule: ManualInventoryEntryRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualInventoryEntry) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualInventoryEntryRequiredContactEmailRule: ManualInventoryEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventoryEntry) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualInventoryEntryRequiredNameRule: ManualInventoryEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualInventoryEntry) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualInventoryEntryPriorityRangeRule: ManualInventoryEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualInventoryEntry) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual inventory entry.
    final class ManualInventoryEntryValidator {
        var rules: [any ManualInventoryEntryRule]

        init(rules: [any ManualInventoryEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualInventoryEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ManualInventoryEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualInventoryEntry]) -> [String: [String]] {
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

    static func defaultManualInventoryEntryValidator() -> ManualInventoryEntryValidator {
        return ManualInventoryEntryValidator(
            rules: [
                ManualInventoryEntryRequiredCurrencyRule(message: "manual inventory entry needs this field"),
                ManualInventoryEntryCodePrefixRule(prefix: "ACM"),
                ManualInventoryEntryRequiredContactEmailRule(message: "manual inventory entry needs this field"),
                ManualInventoryEntryRequiredNameRule(message: "manual inventory entry needs this field"),
                ManualInventoryEntryPriorityRangeRule(min: 80, max: 255),
            ]
        )
    }
}
