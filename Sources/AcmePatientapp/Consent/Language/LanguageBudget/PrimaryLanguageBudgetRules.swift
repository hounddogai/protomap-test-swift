import AcmePlatform
import Foundation

extension Consent {
    /// A rule a primary language budget must pass. Check returns its problems, or none.
    protocol PrimaryLanguageBudgetRule {
        func check(_ item: PrimaryLanguageBudget) -> [String]
    }

    final class PrimaryLanguageBudgetOwnerIDLengthRule: PrimaryLanguageBudgetRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryLanguageBudget) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryLanguageBudgetRequiredOwnerIDRule: PrimaryLanguageBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryLanguageBudget) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryLanguageBudgetAllowedAllergyRule: PrimaryLanguageBudgetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryLanguageBudget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.allergy)) {
                return ["allergy \(item.allergy) is inconsistent"]
            }
            return []
        }
    }

    final class PrimaryLanguageBudgetRequiredLabelRule: PrimaryLanguageBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryLanguageBudget) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryLanguageBudgetRefillsRangeRule: PrimaryLanguageBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryLanguageBudget) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary language budget.
    final class PrimaryLanguageBudgetValidator {
        var rules: [any PrimaryLanguageBudgetRule]

        init(rules: [any PrimaryLanguageBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryLanguageBudget) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryLanguageBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryLanguageBudget]) -> [String: [String]] {
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

    static func defaultPrimaryLanguageBudgetValidator() -> PrimaryLanguageBudgetValidator {
        return PrimaryLanguageBudgetValidator(
            rules: [
                PrimaryLanguageBudgetOwnerIDLengthRule(maxLength: 80),
                PrimaryLanguageBudgetRequiredOwnerIDRule(message: "primary language budget needs this field"),
                PrimaryLanguageBudgetAllowedAllergyRule(allowed: ["fallback", "default"]),
                PrimaryLanguageBudgetRequiredLabelRule(message: "primary language budget needs this field"),
                PrimaryLanguageBudgetRefillsRangeRule(min: 16, max: 86400),
            ]
        )
    }
}
