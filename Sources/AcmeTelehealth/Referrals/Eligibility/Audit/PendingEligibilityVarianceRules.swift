import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a pending eligibility variance must pass. Check returns its problems, or none.
    protocol PendingEligibilityVarianceRule {
        func check(_ item: PendingEligibilityVariance) -> [String]
    }

    final class PendingEligibilityVariancePriorityRangeRule: PendingEligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingEligibilityVariance) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class PendingEligibilityVarianceAttemptsRangeRule: PendingEligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingEligibilityVariance) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingEligibilityVarianceCodeLengthRule: PendingEligibilityVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingEligibilityVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a pending eligibility variance.
    final class PendingEligibilityVarianceValidator {
        var rules: [any PendingEligibilityVarianceRule]

        init(rules: [any PendingEligibilityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingEligibilityVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PendingEligibilityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingEligibilityVariance]) -> [String: [String]] {
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

    static func defaultPendingEligibilityVarianceValidator() -> PendingEligibilityVarianceValidator {
        return PendingEligibilityVarianceValidator(
            rules: [
                PendingEligibilityVariancePriorityRangeRule(min: 32, max: 80),
                PendingEligibilityVarianceAttemptsRangeRule(min: 64, max: 120),
                PendingEligibilityVarianceCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
