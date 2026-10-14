import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched read threshold must pass. Check returns its problems, or none.
    protocol BatchedReadThresholdRule {
        func check(_ item: BatchedReadThreshold) -> [String]
    }

    final class BatchedReadThresholdTitleLengthRule: BatchedReadThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedReadThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedReadThresholdRequiredTitleRule: BatchedReadThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedReadThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedReadThresholdRateRangeRule: BatchedReadThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedReadThreshold) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched read threshold.
    final class BatchedReadThresholdValidator {
        var rules: [any BatchedReadThresholdRule]

        init(rules: [any BatchedReadThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedReadThreshold) -> [String] {
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

        func requireValid(_ item: BatchedReadThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedReadThreshold]) -> [String: [String]] {
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

    static func defaultBatchedReadThresholdValidator() -> BatchedReadThresholdValidator {
        return BatchedReadThresholdValidator(
            rules: [
                BatchedReadThresholdTitleLengthRule(maxLength: 16),
                BatchedReadThresholdRequiredTitleRule(message: "batched read threshold needs an entry"),
                BatchedReadThresholdRateRangeRule(min: 1.5, max: 3581.3),
            ]
        )
    }
}
