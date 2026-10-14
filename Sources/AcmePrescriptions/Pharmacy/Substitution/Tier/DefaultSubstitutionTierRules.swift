import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a default substitution tier must pass. Check returns its problems, or none.
    protocol DefaultSubstitutionTierRule {
        func check(_ item: DefaultSubstitutionTier) -> [String]
    }

    final class DefaultSubstitutionTierDosageMgRangeRule: DefaultSubstitutionTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultSubstitutionTier) -> [String] {
            let value = item.dosageMg
            if value < min || value > max {
                return ["dosage mg \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultSubstitutionTierPayerLengthRule: DefaultSubstitutionTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultSubstitutionTier) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultSubstitutionTierActiveGuardRule: DefaultSubstitutionTierRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: DefaultSubstitutionTier) -> [String] {
            if item.active && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a default substitution tier.
    final class DefaultSubstitutionTierValidator {
        var rules: [any DefaultSubstitutionTierRule]

        init(rules: [any DefaultSubstitutionTierRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultSubstitutionTier) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultSubstitutionTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultSubstitutionTier]) -> [String: [String]] {
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

    static func defaultDefaultSubstitutionTierValidator() -> DefaultSubstitutionTierValidator {
        return DefaultSubstitutionTierValidator(
            rules: [
                DefaultSubstitutionTierDosageMgRangeRule(min: 5.6, max: 2901.9),
                DefaultSubstitutionTierPayerLengthRule(maxLength: 80),
                DefaultSubstitutionTierActiveGuardRule(limit: 8.9),
            ]
        )
    }
}
