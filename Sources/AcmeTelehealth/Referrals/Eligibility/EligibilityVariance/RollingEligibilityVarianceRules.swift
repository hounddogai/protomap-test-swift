import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a rolling eligibility variance must pass. Check returns its problems, or none.
    protocol RollingEligibilityVarianceRule {
        func check(_ item: RollingEligibilityVariance) -> [String]
    }

    final class RollingEligibilityVarianceTitleLengthRule: RollingEligibilityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingEligibilityVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingEligibilityVarianceRequiredCodeRule: RollingEligibilityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingEligibilityVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingEligibilityVarianceWeightRangeRule: RollingEligibilityVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingEligibilityVariance) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingEligibilityVarianceQuantityRangeRule: RollingEligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingEligibilityVariance) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingEligibilityVarianceEndsAtRangeRule: RollingEligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingEligibilityVariance) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rolling eligibility variance.
    final class RollingEligibilityVarianceValidator {
        var rules: [any RollingEligibilityVarianceRule]

        init(rules: [any RollingEligibilityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingEligibilityVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingEligibilityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingEligibilityVariance]) -> [String: [String]] {
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

    static func defaultRollingEligibilityVarianceValidator() -> RollingEligibilityVarianceValidator {
        return RollingEligibilityVarianceValidator(
            rules: [
                RollingEligibilityVarianceTitleLengthRule(maxLength: 86400),
                RollingEligibilityVarianceRequiredCodeRule(message: "rolling eligibility variance needs an entry"),
                RollingEligibilityVarianceWeightRangeRule(min: 0.5, max: 4289.6),
                RollingEligibilityVarianceQuantityRangeRule(min: 16, max: 64),
                RollingEligibilityVarianceEndsAtRangeRule(min: 80, max: 86400),
            ]
        )
    }
}
