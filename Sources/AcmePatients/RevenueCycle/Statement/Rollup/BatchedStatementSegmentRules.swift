import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched statement segment must pass. Check returns its problems, or none.
    protocol BatchedStatementSegmentRule {
        func check(_ item: BatchedStatementSegment) -> [String]
    }

    final class BatchedStatementSegmentRequiredSegmentRule: BatchedStatementSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementSegment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStatementSegmentPriorityRangeRule: BatchedStatementSegmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedStatementSegment) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedStatementSegmentReviewerLengthRule: BatchedStatementSegmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementSegment) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStatementSegmentRequiredReviewerRule: BatchedStatementSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementSegment) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStatementSegmentRequiredCodeRule: BatchedStatementSegmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementSegment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched statement segment.
    final class BatchedStatementSegmentValidator {
        var rules: [any BatchedStatementSegmentRule]

        init(rules: [any BatchedStatementSegmentRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStatementSegment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedStatementSegment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStatementSegment]) -> [String: [String]] {
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

    static func defaultBatchedStatementSegmentValidator() -> BatchedStatementSegmentValidator {
        return BatchedStatementSegmentValidator(
            rules: [
                BatchedStatementSegmentRequiredSegmentRule(message: "batched statement segment needs a value"),
                BatchedStatementSegmentPriorityRangeRule(min: 80, max: 1000),
                BatchedStatementSegmentReviewerLengthRule(maxLength: 80),
                BatchedStatementSegmentRequiredReviewerRule(message: "batched statement segment needs an entry"),
                BatchedStatementSegmentRequiredCodeRule(message: "batched statement segment needs a value"),
            ]
        )
    }
}
