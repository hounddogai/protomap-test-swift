import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan tier must pass. Check returns its problems, or none.
    protocol DischargePlanTierRule {
        func check(_ item: DischargePlanTier) -> [String]
    }

    final class DischargePlanTierEndsAtRangeRule: DischargePlanTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanTier) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DischargePlanTierAllowedNameRule: DischargePlanTierRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DischargePlanTier) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is above maximum"]
            }
            return []
        }
    }

    final class DischargePlanTierRequiredTimezoneRule: DischargePlanTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanTier) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan tier.
    final class DischargePlanTierValidator {
        var rules: [any DischargePlanTierRule]

        init(rules: [any DischargePlanTierRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanTier) -> [String] {
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

        func requireValid(_ item: DischargePlanTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanTier]) -> [String: [String]] {
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

    static func defaultDischargePlanTierValidator() -> DischargePlanTierValidator {
        return DischargePlanTierValidator(
            rules: [
                DischargePlanTierEndsAtRangeRule(min: 32, max: 255),
                DischargePlanTierAllowedNameRule(allowed: ["regional", "scheduled", "legacy"]),
                DischargePlanTierRequiredTimezoneRule(message: "discharge plan tier needs an entry"),
            ]
        )
    }
}
