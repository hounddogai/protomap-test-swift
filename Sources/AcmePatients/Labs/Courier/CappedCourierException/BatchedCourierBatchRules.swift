import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched courier batch must pass. Check returns its problems, or none.
    protocol BatchedCourierBatchRule {
        func check(_ item: BatchedCourierBatch) -> [String]
    }

    final class BatchedCourierBatchRequiredExternalRefRule: BatchedCourierBatchRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCourierBatch) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCourierBatchContactEmailLengthRule: BatchedCourierBatchRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCourierBatch) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCourierBatchMinimumRangeRule: BatchedCourierBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCourierBatch) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCourierBatchWeightRangeRule: BatchedCourierBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCourierBatch) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCourierBatchRatioRangeRule: BatchedCourierBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCourierBatch) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCourierBatchAmountRangeRule: BatchedCourierBatchRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCourierBatch) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched courier batch.
    final class BatchedCourierBatchValidator {
        var rules: [any BatchedCourierBatchRule]

        init(rules: [any BatchedCourierBatchRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCourierBatch) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedCourierBatch) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCourierBatch]) -> [String: [String]] {
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

    static func defaultBatchedCourierBatchValidator() -> BatchedCourierBatchValidator {
        return BatchedCourierBatchValidator(
            rules: [
                BatchedCourierBatchRequiredExternalRefRule(message: "batched courier batch needs an entry"),
                BatchedCourierBatchContactEmailLengthRule(maxLength: 1000),
                BatchedCourierBatchMinimumRangeRule(min: 5.0, max: 3457.9),
                BatchedCourierBatchWeightRangeRule(min: 1.1, max: 1724.8),
                BatchedCourierBatchRatioRangeRule(min: 3.2, max: 2358.5),
                BatchedCourierBatchAmountRangeRule(min: 3.2, max: 4206.8),
            ]
        )
    }
}
