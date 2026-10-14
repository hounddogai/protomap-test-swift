import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a eligibility variance must pass. Check returns its problems, or none.
    protocol EligibilityVarianceRule {
        func check(_ item: EligibilityVariance) -> [String]
    }

    final class EligibilityVarianceCodePrefixRule: EligibilityVarianceRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: EligibilityVariance) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class EligibilityVarianceDurationMinutesRangeRule: EligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityVariance) -> [String] {
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

    final class EligibilityVarianceCodeLengthRule: EligibilityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: EligibilityVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class EligibilityVarianceQuantityRangeRule: EligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: EligibilityVariance) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a eligibility variance.
    final class EligibilityVarianceValidator {
        var rules: [any EligibilityVarianceRule]

        init(rules: [any EligibilityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: EligibilityVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: EligibilityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [EligibilityVariance]) -> [String: [String]] {
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

    static func defaultEligibilityVarianceValidator() -> EligibilityVarianceValidator {
        return EligibilityVarianceValidator(
            rules: [
                EligibilityVarianceCodePrefixRule(prefix: "REF"),
                EligibilityVarianceDurationMinutesRangeRule(min: 120, max: 3600),
                EligibilityVarianceCodeLengthRule(maxLength: 32),
                EligibilityVarianceQuantityRangeRule(min: 16, max: 3600),
            ]
        )
    }
}
