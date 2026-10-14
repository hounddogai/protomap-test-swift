import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched overtime rollup must pass. Check returns its problems, or none.
    protocol BatchedOvertimeRollupRule {
        func check(_ item: BatchedOvertimeRollup) -> [String]
    }

    final class BatchedOvertimeRollupStartsAtRangeRule: BatchedOvertimeRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeRollup) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedOvertimeRollupPriorityRangeRule: BatchedOvertimeRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeRollup) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedOvertimeRollupEndsAtRangeRule: BatchedOvertimeRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeRollup) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedOvertimeRollupLabelLengthRule: BatchedOvertimeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOvertimeRollup) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOvertimeRollupCodeLengthRule: BatchedOvertimeRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedOvertimeRollup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedOvertimeRollupCodePrefixRule: BatchedOvertimeRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedOvertimeRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched overtime rollup.
    final class BatchedOvertimeRollupValidator {
        var rules: [any BatchedOvertimeRollupRule]

        init(rules: [any BatchedOvertimeRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOvertimeRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedOvertimeRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOvertimeRollup]) -> [String: [String]] {
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

    static func defaultBatchedOvertimeRollupValidator() -> BatchedOvertimeRollupValidator {
        return BatchedOvertimeRollupValidator(
            rules: [
                BatchedOvertimeRollupStartsAtRangeRule(min: 64, max: 120),
                BatchedOvertimeRollupPriorityRangeRule(min: 80, max: 3600),
                BatchedOvertimeRollupEndsAtRangeRule(min: 32, max: 64),
                BatchedOvertimeRollupLabelLengthRule(maxLength: 3600),
                BatchedOvertimeRollupCodeLengthRule(maxLength: 120),
                BatchedOvertimeRollupCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
