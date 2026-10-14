import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched closure score must pass. Check returns its problems, or none.
    protocol BatchedClosureScoreRule {
        func check(_ item: BatchedClosureScore) -> [String]
    }

    final class BatchedClosureScoreCodeLengthRule: BatchedClosureScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedClosureScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedClosureScoreQuantityRangeRule: BatchedClosureScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClosureScore) -> [String] {
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

    final class BatchedClosureScoreScoreRangeRule: BatchedClosureScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClosureScore) -> [String] {
            let value = item.score
            var problems: [String] = []
            if value < min {
                problems.append("score \(value) is below \(min)")
            }
            if value > max {
                problems.append("score \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a batched closure score.
    final class BatchedClosureScoreValidator {
        var rules: [any BatchedClosureScoreRule]

        init(rules: [any BatchedClosureScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedClosureScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedClosureScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedClosureScore]) -> [String: [String]] {
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

    static func defaultBatchedClosureScoreValidator() -> BatchedClosureScoreValidator {
        return BatchedClosureScoreValidator(
            rules: [
                BatchedClosureScoreCodeLengthRule(maxLength: 1000),
                BatchedClosureScoreQuantityRangeRule(min: 16, max: 16),
                BatchedClosureScoreScoreRangeRule(min: 2.3, max: 2831.0),
            ]
        )
    }
}
