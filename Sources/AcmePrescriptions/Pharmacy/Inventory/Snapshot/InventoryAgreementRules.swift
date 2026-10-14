import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a inventory agreement must pass. Check returns its problems, or none.
    protocol InventoryAgreementRule {
        func check(_ item: InventoryAgreement) -> [String]
    }

    final class InventoryAgreementCodePrefixRule: InventoryAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InventoryAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InventoryAgreementRequiredTitleRule: InventoryAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAgreement) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAgreementTitleLengthRule: InventoryAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InventoryAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InventoryAgreementRequiredLocaleRule: InventoryAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InventoryAgreement) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InventoryAgreementAllowedTitleRule: InventoryAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InventoryAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a inventory agreement.
    final class InventoryAgreementValidator {
        var rules: [any InventoryAgreementRule]

        init(rules: [any InventoryAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: InventoryAgreement) -> [String] {
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

        func requireValid(_ item: InventoryAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InventoryAgreement]) -> [String: [String]] {
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

    static func defaultInventoryAgreementValidator() -> InventoryAgreementValidator {
        return InventoryAgreementValidator(
            rules: [
                InventoryAgreementCodePrefixRule(prefix: "Q"),
                InventoryAgreementRequiredTitleRule(message: "inventory agreement needs a value"),
                InventoryAgreementTitleLengthRule(maxLength: 32),
                InventoryAgreementRequiredLocaleRule(message: "inventory agreement needs an entry"),
                InventoryAgreementAllowedTitleRule(allowed: ["global", "lenient"]),
            ]
        )
    }
}
