import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy interaction budget must pass. Check returns its problems, or none.
    protocol LegacyInteractionBudgetRule {
        func check(_ item: LegacyInteractionBudget) -> [String]
    }

    final class LegacyInteractionBudgetRequiredFacilityRule: LegacyInteractionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionBudget) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionBudgetCodePrefixRule: LegacyInteractionBudgetRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LegacyInteractionBudget) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LegacyInteractionBudgetRequiredTimezoneRule: LegacyInteractionBudgetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyInteractionBudget) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyInteractionBudgetVisitMinutesRangeRule: LegacyInteractionBudgetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyInteractionBudget) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy interaction budget.
    final class LegacyInteractionBudgetValidator {
        var rules: [any LegacyInteractionBudgetRule]

        init(rules: [any LegacyInteractionBudgetRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyInteractionBudget) -> [String] {
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

        func requireValid(_ item: LegacyInteractionBudget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyInteractionBudget]) -> [String: [String]] {
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

    static func defaultLegacyInteractionBudgetValidator() -> LegacyInteractionBudgetValidator {
        return LegacyInteractionBudgetValidator(
            rules: [
                LegacyInteractionBudgetRequiredFacilityRule(message: "legacy interaction budget needs an entry"),
                LegacyInteractionBudgetCodePrefixRule(prefix: "ACM"),
                LegacyInteractionBudgetRequiredTimezoneRule(message: "legacy interaction budget needs a value"),
                LegacyInteractionBudgetVisitMinutesRangeRule(min: 32, max: 80),
            ]
        )
    }
}
