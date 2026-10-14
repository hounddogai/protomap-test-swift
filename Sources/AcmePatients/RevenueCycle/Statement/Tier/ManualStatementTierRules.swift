import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a manual statement tier must pass. Check returns its problems, or none.
    protocol ManualStatementTierRule {
        func check(_ item: ManualStatementTier) -> [String]
    }

    final class ManualStatementTierRequiredCountryRule: ManualStatementTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualStatementTier) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ManualStatementTierAllowedNameRule: ManualStatementTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualStatementTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class ManualStatementTierDurationMinutesRangeRule: ManualStatementTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualStatementTier) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ManualStatementTierRequiredCodeRule: ManualStatementTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ManualStatementTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a manual statement tier.
    final class ManualStatementTierValidator {
        var rules: [any ManualStatementTierRule]

        init(rules: [any ManualStatementTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualStatementTier) -> [String] {
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

        func requireValid(_ item: ManualStatementTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualStatementTier]) -> [String: [String]] {
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

    static func defaultManualStatementTierValidator() -> ManualStatementTierValidator {
        return ManualStatementTierValidator(
            rules: [
                ManualStatementTierRequiredCountryRule(message: "manual statement tier needs this field"),
                ManualStatementTierAllowedNameRule(allowed: ["seasonal", "global"]),
                ManualStatementTierDurationMinutesRangeRule(min: 80, max: 255),
                ManualStatementTierRequiredCodeRule(message: "manual statement tier needs this field"),
            ]
        )
    }
}
