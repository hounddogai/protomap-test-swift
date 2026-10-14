import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched closure estimate must pass. Check returns its problems, or none.
    protocol BatchedClosureEstimateRule {
        func check(_ item: BatchedClosureEstimate) -> [String]
    }

    final class BatchedClosureEstimateRequiredCodeRule: BatchedClosureEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClosureEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedClosureEstimateLabelLengthRule: BatchedClosureEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedClosureEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedClosureEstimateRequiredExternalRefRule: BatchedClosureEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClosureEstimate) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedClosureEstimateRefillsRangeRule: BatchedClosureEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClosureEstimate) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedClosureEstimateRequiredSegmentRule: BatchedClosureEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedClosureEstimate) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched closure estimate.
    final class BatchedClosureEstimateValidator {
        var rules: [any BatchedClosureEstimateRule]

        init(rules: [any BatchedClosureEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedClosureEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedClosureEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedClosureEstimate]) -> [String: [String]] {
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

    static func defaultBatchedClosureEstimateValidator() -> BatchedClosureEstimateValidator {
        return BatchedClosureEstimateValidator(
            rules: [
                BatchedClosureEstimateRequiredCodeRule(message: "batched closure estimate needs an entry"),
                BatchedClosureEstimateLabelLengthRule(maxLength: 1000),
                BatchedClosureEstimateRequiredExternalRefRule(message: "batched closure estimate needs a value"),
                BatchedClosureEstimateRefillsRangeRule(min: 64, max: 80),
                BatchedClosureEstimateRequiredSegmentRule(message: "batched closure estimate needs a value"),
            ]
        )
    }
}
