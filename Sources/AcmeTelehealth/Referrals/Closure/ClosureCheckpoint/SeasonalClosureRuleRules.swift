import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a seasonal closure rule must pass. Check returns its problems, or none.
    protocol SeasonalClosureRuleRule {
        func check(_ item: SeasonalClosureRule) -> [String]
    }

    final class SeasonalClosureRuleMarginRangeRule: SeasonalClosureRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalClosureRule) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalClosureRuleDiscountRangeRule: SeasonalClosureRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalClosureRule) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalClosureRuleLabelLengthRule: SeasonalClosureRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalClosureRule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalClosureRuleWeightRangeRule: SeasonalClosureRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalClosureRule) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalClosureRuleAllowedCodeRule: SeasonalClosureRuleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalClosureRule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class SeasonalClosureRuleRequiredClinicianIDRule: SeasonalClosureRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalClosureRule) -> [String] {
            if item.clinicianID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal closure rule.
    final class SeasonalClosureRuleValidator {
        var rules: [any SeasonalClosureRuleRule]

        init(rules: [any SeasonalClosureRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalClosureRule) -> [String] {
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

        func requireValid(_ item: SeasonalClosureRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalClosureRule]) -> [String: [String]] {
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

    static func defaultSeasonalClosureRuleValidator() -> SeasonalClosureRuleValidator {
        return SeasonalClosureRuleValidator(
            rules: [
                SeasonalClosureRuleMarginRangeRule(min: 5.4, max: 3465.1),
                SeasonalClosureRuleDiscountRangeRule(min: 1.4, max: 1161.4),
                SeasonalClosureRuleLabelLengthRule(maxLength: 3600),
                SeasonalClosureRuleWeightRangeRule(min: 2.3, max: 4757.9),
                SeasonalClosureRuleAllowedCodeRule(allowed: ["manual", "lenient", "default"]),
                SeasonalClosureRuleRequiredClinicianIDRule(message: "seasonal closure rule needs a value"),
            ]
        )
    }
}
