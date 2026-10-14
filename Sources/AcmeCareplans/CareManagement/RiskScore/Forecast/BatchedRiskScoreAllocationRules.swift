import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a batched risk score allocation must pass. Check returns its problems, or none.
    protocol BatchedRiskScoreAllocationRule {
        func check(_ item: BatchedRiskScoreAllocation) -> [String]
    }

    final class BatchedRiskScoreAllocationRequiredCodeRule: BatchedRiskScoreAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRiskScoreAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedRiskScoreAllocationDiscountRangeRule: BatchedRiskScoreAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedRiskScoreAllocation) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedRiskScoreAllocationRequiredContactEmailRule: BatchedRiskScoreAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedRiskScoreAllocation) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched risk score allocation.
    final class BatchedRiskScoreAllocationValidator {
        var rules: [any BatchedRiskScoreAllocationRule]

        init(rules: [any BatchedRiskScoreAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedRiskScoreAllocation) -> [String] {
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

        func requireValid(_ item: BatchedRiskScoreAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedRiskScoreAllocation]) -> [String: [String]] {
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

    static func defaultBatchedRiskScoreAllocationValidator() -> BatchedRiskScoreAllocationValidator {
        return BatchedRiskScoreAllocationValidator(
            rules: [
                BatchedRiskScoreAllocationRequiredCodeRule(message: "batched risk score allocation needs this field"),
                BatchedRiskScoreAllocationDiscountRangeRule(min: 8.5, max: 3138.4),
                BatchedRiskScoreAllocationRequiredContactEmailRule(
                    message: "batched risk score allocation needs this field"
                ),
            ]
        )
    }
}
