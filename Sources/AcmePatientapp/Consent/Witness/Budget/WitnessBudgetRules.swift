import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness budget must pass. Check returns its problems, or none.
    protocol WitnessBudgetRule {
        func check(_ item: WitnessBudget) -> [String]
    }

    final class WitnessBudgetAllergyLengthRule: WitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessBudget) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessBudgetRefillsRangeRule: WitnessBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WitnessBudget) -> [String] {
            let value = item.refills
            var problems: [String] = []
            if value < min {
                problems.append("refills \(value) is below \(min)")
            }
            if value > max {
                problems.append("refills \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WitnessBudgetCodePrefixRule: WitnessBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WitnessBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WitnessBudgetExternalRefLengthRule: WitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessBudget) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessBudgetNameLengthRule: WitnessBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessBudget) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessBudgetRequiredCodeRule: WitnessBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a witness budget.
    final class WitnessBudgetValidator {
        var rules: [any WitnessBudgetRule]

        init(rules: [any WitnessBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessBudget) -> [String] {
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

        func requireValid(_ item: WitnessBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessBudget]) -> [String: [String]] {
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

    static func defaultWitnessBudgetValidator() -> WitnessBudgetValidator {
        return WitnessBudgetValidator(
            rules: [
                WitnessBudgetAllergyLengthRule(maxLength: 3600),
                WitnessBudgetRefillsRangeRule(min: 80, max: 120),
                WitnessBudgetCodePrefixRule(prefix: "ACM"),
                WitnessBudgetExternalRefLengthRule(maxLength: 3600),
                WitnessBudgetNameLengthRule(maxLength: 64),
                WitnessBudgetRequiredCodeRule(message: "witness budget needs this field"),
            ]
        )
    }
}
