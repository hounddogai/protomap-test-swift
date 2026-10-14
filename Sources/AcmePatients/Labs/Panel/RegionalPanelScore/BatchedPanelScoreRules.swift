import AcmePlatform
import Foundation

extension Labs {
    /// A rule a batched panel score must pass. Check returns its problems, or none.
    protocol BatchedPanelScoreRule {
        func check(_ item: BatchedPanelScore) -> [String]
    }

    final class BatchedPanelScoreCodeLengthRule: BatchedPanelScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedPanelScore) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedPanelScorePriorityRangeRule: BatchedPanelScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedPanelScore) -> [String] {
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

    final class BatchedPanelScoreCeilingRangeRule: BatchedPanelScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedPanelScore) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedPanelScoreSequenceRangeRule: BatchedPanelScoreRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedPanelScore) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedPanelScoreAllowedCodeRule: BatchedPanelScoreRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedPanelScore) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    /// Runs every rule of a batched panel score.
    final class BatchedPanelScoreValidator {
        var rules: [any BatchedPanelScoreRule]

        init(rules: [any BatchedPanelScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedPanelScore) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedPanelScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedPanelScore]) -> [String: [String]] {
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

    static func defaultBatchedPanelScoreValidator() -> BatchedPanelScoreValidator {
        return BatchedPanelScoreValidator(
            rules: [
                BatchedPanelScoreCodeLengthRule(maxLength: 1000),
                BatchedPanelScorePriorityRangeRule(min: 1000, max: 1000),
                BatchedPanelScoreCeilingRangeRule(min: 5.6, max: 3153.6),
                BatchedPanelScoreSequenceRangeRule(min: 16, max: 64),
                BatchedPanelScoreAllowedCodeRule(allowed: ["batched", "legacy"]),
            ]
        )
    }
}
