import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a legacy eligibility baseline must pass. Check returns its problems, or none.
    protocol LegacyEligibilityBaselineRule {
        func check(_ item: LegacyEligibilityBaseline) -> [String]
    }

    final class LegacyEligibilityBaselineRequiredNameRule: LegacyEligibilityBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyEligibilityBaseline) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyEligibilityBaselineRequiredCurrencyRule: LegacyEligibilityBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyEligibilityBaseline) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyEligibilityBaselineMaximumRangeRule: LegacyEligibilityBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyEligibilityBaseline) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyEligibilityBaselineCodeLengthRule: LegacyEligibilityBaselineRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyEligibilityBaseline) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyEligibilityBaselineCeilingRangeRule: LegacyEligibilityBaselineRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyEligibilityBaseline) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyEligibilityBaselineRequiredPayerRule: LegacyEligibilityBaselineRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyEligibilityBaseline) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy eligibility baseline.
    final class LegacyEligibilityBaselineValidator {
        var rules: [any LegacyEligibilityBaselineRule]

        init(rules: [any LegacyEligibilityBaselineRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyEligibilityBaseline) -> [String] {
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

        func requireValid(_ item: LegacyEligibilityBaseline) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyEligibilityBaseline]) -> [String: [String]] {
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

    static func defaultLegacyEligibilityBaselineValidator() -> LegacyEligibilityBaselineValidator {
        return LegacyEligibilityBaselineValidator(
            rules: [
                LegacyEligibilityBaselineRequiredNameRule(message: "legacy eligibility baseline needs a value"),
                LegacyEligibilityBaselineRequiredCurrencyRule(message: "legacy eligibility baseline needs this field"),
                LegacyEligibilityBaselineMaximumRangeRule(min: 9.1, max: 291.0),
                LegacyEligibilityBaselineCodeLengthRule(maxLength: 1000),
                LegacyEligibilityBaselineCeilingRangeRule(min: 3.6, max: 1170.5),
                LegacyEligibilityBaselineRequiredPayerRule(message: "legacy eligibility baseline needs a value"),
            ]
        )
    }
}
