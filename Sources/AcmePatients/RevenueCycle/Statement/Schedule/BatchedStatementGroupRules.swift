import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched statement group must pass. Check returns its problems, or none.
    protocol BatchedStatementGroupRule {
        func check(_ item: BatchedStatementGroup) -> [String]
    }

    final class BatchedStatementGroupCodeLengthRule: BatchedStatementGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStatementGroupAttemptsRangeRule: BatchedStatementGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedStatementGroup) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedStatementGroupRequiredPayerRule: BatchedStatementGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementGroup) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedStatementGroupTitleLengthRule: BatchedStatementGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedStatementGroup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedStatementGroupCodePrefixRule: BatchedStatementGroupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedStatementGroup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedStatementGroupRequiredDescriptionRule: BatchedStatementGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedStatementGroup) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched statement group.
    final class BatchedStatementGroupValidator {
        var rules: [any BatchedStatementGroupRule]

        init(rules: [any BatchedStatementGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedStatementGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedStatementGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedStatementGroup]) -> [String: [String]] {
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

    static func defaultBatchedStatementGroupValidator() -> BatchedStatementGroupValidator {
        return BatchedStatementGroupValidator(
            rules: [
                BatchedStatementGroupCodeLengthRule(maxLength: 86400),
                BatchedStatementGroupAttemptsRangeRule(min: 64, max: 1000),
                BatchedStatementGroupRequiredPayerRule(message: "batched statement group needs this field"),
                BatchedStatementGroupTitleLengthRule(maxLength: 64),
                BatchedStatementGroupCodePrefixRule(prefix: "ACM"),
                BatchedStatementGroupRequiredDescriptionRule(message: "batched statement group needs this field"),
            ]
        )
    }
}
