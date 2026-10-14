import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a batched care protocol threshold must pass. Check returns its problems, or none.
    protocol BatchedCareProtocolThresholdRule {
        func check(_ item: BatchedCareProtocolThreshold) -> [String]
    }

    final class BatchedCareProtocolThresholdSequenceRangeRule: BatchedCareProtocolThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCareProtocolThreshold) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedCareProtocolThresholdUpdatedAtRangeRule: BatchedCareProtocolThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCareProtocolThreshold) -> [String] {
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

    final class BatchedCareProtocolThresholdTimezoneLengthRule: BatchedCareProtocolThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCareProtocolThreshold) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCareProtocolThresholdRequiredTitleRule: BatchedCareProtocolThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCareProtocolThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched care protocol threshold.
    final class BatchedCareProtocolThresholdValidator {
        var rules: [any BatchedCareProtocolThresholdRule]

        init(rules: [any BatchedCareProtocolThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCareProtocolThreshold) -> [String] {
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

        func requireValid(_ item: BatchedCareProtocolThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCareProtocolThreshold]) -> [String: [String]] {
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

    static func defaultBatchedCareProtocolThresholdValidator() -> BatchedCareProtocolThresholdValidator {
        return BatchedCareProtocolThresholdValidator(
            rules: [
                BatchedCareProtocolThresholdSequenceRangeRule(min: 120, max: 86400),
                BatchedCareProtocolThresholdUpdatedAtRangeRule(min: 32, max: 120),
                BatchedCareProtocolThresholdTimezoneLengthRule(maxLength: 86400),
                BatchedCareProtocolThresholdRequiredTitleRule(
                    message: "batched care protocol threshold needs an entry"
                ),
            ]
        )
    }
}
