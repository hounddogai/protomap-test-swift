import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped eligibility variance must pass. Check returns its problems, or none.
    protocol CappedEligibilityVarianceRule {
        func check(_ item: CappedEligibilityVariance) -> [String]
    }

    final class CappedEligibilityVarianceAllowedCodeRule: CappedEligibilityVarianceRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedEligibilityVariance) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is out of range"]
            }
            return []
        }
    }

    final class CappedEligibilityVarianceCodePrefixRule: CappedEligibilityVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedEligibilityVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedEligibilityVarianceRatioRangeRule: CappedEligibilityVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedEligibilityVariance) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedEligibilityVarianceCeilingRangeRule: CappedEligibilityVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedEligibilityVariance) -> [String] {
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

    final class CappedEligibilityVarianceNameLengthRule: CappedEligibilityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedEligibilityVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped eligibility variance.
    final class CappedEligibilityVarianceValidator {
        var rules: [any CappedEligibilityVarianceRule]

        init(rules: [any CappedEligibilityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedEligibilityVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedEligibilityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedEligibilityVariance]) -> [String: [String]] {
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

    static func defaultCappedEligibilityVarianceValidator() -> CappedEligibilityVarianceValidator {
        return CappedEligibilityVarianceValidator(
            rules: [
                CappedEligibilityVarianceAllowedCodeRule(allowed: ["scheduled", "weighted"]),
                CappedEligibilityVarianceCodePrefixRule(prefix: "X"),
                CappedEligibilityVarianceRatioRangeRule(min: 0.6, max: 3135.6),
                CappedEligibilityVarianceCeilingRangeRule(min: 8.6, max: 2629.0),
                CappedEligibilityVarianceNameLengthRule(maxLength: 255),
            ]
        )
    }
}
