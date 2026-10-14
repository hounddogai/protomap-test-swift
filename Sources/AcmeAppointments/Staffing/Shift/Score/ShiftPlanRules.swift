import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift plan must pass. Check returns its problems, or none.
    protocol ShiftPlanRule {
        func check(_ item: ShiftPlan) -> [String]
    }

    final class ShiftPlanCodeLengthRule: ShiftPlanRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftPlan) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ShiftPlanAllowedLocaleRule: ShiftPlanRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ShiftPlan) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.locale)) {
                return ["locale \(item.locale) is too long"]
            }
            return []
        }
    }

    final class ShiftPlanRequiredAllergyRule: ShiftPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftPlan) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftPlanRequiredCurrencyRule: ShiftPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftPlan) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftPlanPinnedGuardRule: ShiftPlanRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: ShiftPlan) -> [String] {
            if item.pinned && (item.dosageMg > limit) {
                return ["dosage mg \(item.dosageMg) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class ShiftPlanCodePrefixRule: ShiftPlanRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ShiftPlan) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift plan.
    final class ShiftPlanValidator {
        var rules: [any ShiftPlanRule]

        init(rules: [any ShiftPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftPlan) -> [String] {
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

        func requireValid(_ item: ShiftPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftPlan]) -> [String: [String]] {
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

    static func defaultShiftPlanValidator() -> ShiftPlanValidator {
        return ShiftPlanValidator(
            rules: [
                ShiftPlanCodeLengthRule(maxLength: 1000),
                ShiftPlanAllowedLocaleRule(allowed: ["capped"]),
                ShiftPlanRequiredAllergyRule(message: "shift plan needs a value"),
                ShiftPlanRequiredCurrencyRule(message: "shift plan needs this field"),
                ShiftPlanPinnedGuardRule(limit: 3.7),
                ShiftPlanCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
