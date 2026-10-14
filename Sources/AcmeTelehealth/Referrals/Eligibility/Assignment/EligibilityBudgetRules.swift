import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility budget must pass. Check returns its problems, or none.
    protocol EligibilityBudgetRule {
        func check(_ item: EligibilityBudget) -> [String]
    }

    final class EligibilityBudgetAllowedOwnerIDRule: EligibilityBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: EligibilityBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.ownerID)) {
                return ["owner id \(item.ownerID) is not allowed"]
            }
            return []
        }
    }

    final class EligibilityBudgetOwnerIDLengthRule: EligibilityBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityBudget) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityBudgetRequiredNameRule: EligibilityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityBudget) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class EligibilityBudgetCodePrefixRule: EligibilityBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityBudgetRequiredCodeRule: EligibilityBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: EligibilityBudget) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a eligibility budget.
    final class EligibilityBudgetValidator {
        var rules: [any EligibilityBudgetRule]

        init(rules: [any EligibilityBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityBudget) -> [String] {
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

        func requireValid(_ item: EligibilityBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityBudget]) -> [String: [String]] {
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

    static func defaultEligibilityBudgetValidator() -> EligibilityBudgetValidator {
        return EligibilityBudgetValidator(
            rules: [
                EligibilityBudgetAllowedOwnerIDRule(allowed: []),
                EligibilityBudgetOwnerIDLengthRule(maxLength: 3600),
                EligibilityBudgetRequiredNameRule(message: "eligibility budget needs an entry"),
                EligibilityBudgetCodePrefixRule(prefix: "OPS"),
                EligibilityBudgetRequiredCodeRule(message: "eligibility budget needs a value"),
            ]
        )
    }
}
