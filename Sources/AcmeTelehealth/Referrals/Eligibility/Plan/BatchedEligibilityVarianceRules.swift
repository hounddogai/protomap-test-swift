import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched eligibility variance must pass. Check returns its problems, or none.
    protocol BatchedEligibilityVarianceRule {
        func check(_ item: BatchedEligibilityVariance) -> [String]
    }

    final class BatchedEligibilityVarianceRequiredTimezoneRule: BatchedEligibilityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityVariance) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedEligibilityVarianceRequiredLabelRule: BatchedEligibilityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedEligibilityVarianceUpdatedAtRangeRule: BatchedEligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedEligibilityVariance) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedEligibilityVarianceAttemptsRangeRule: BatchedEligibilityVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedEligibilityVariance) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedEligibilityVarianceRequiredCodeRule: BatchedEligibilityVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedEligibilityVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched eligibility variance.
    final class BatchedEligibilityVarianceValidator {
        var rules: [any BatchedEligibilityVarianceRule]

        init(rules: [any BatchedEligibilityVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedEligibilityVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedEligibilityVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedEligibilityVariance]) -> [String: [String]] {
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

    static func defaultBatchedEligibilityVarianceValidator() -> BatchedEligibilityVarianceValidator {
        return BatchedEligibilityVarianceValidator(
            rules: [
                BatchedEligibilityVarianceRequiredTimezoneRule(
                    message: "batched eligibility variance needs this field"
                ),
                BatchedEligibilityVarianceRequiredLabelRule(message: "batched eligibility variance needs an entry"),
                BatchedEligibilityVarianceUpdatedAtRangeRule(min: 80, max: 255),
                BatchedEligibilityVarianceAttemptsRangeRule(min: 80, max: 3600),
                BatchedEligibilityVarianceRequiredCodeRule(message: "batched eligibility variance needs an entry"),
            ]
        )
    }
}
