import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched isolation rollup must pass. Check returns its problems, or none.
    protocol BatchedIsolationRollupRule {
        func check(_ item: BatchedIsolationRollup) -> [String]
    }

    final class BatchedIsolationRollupAllowedDescriptionRule: BatchedIsolationRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedIsolationRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.description)) {
                return ["description \(item.description) is blocked"]
            }
            return []
        }
    }

    final class BatchedIsolationRollupRequiredCodeRule: BatchedIsolationRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedIsolationRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedIsolationRollupTitleLengthRule: BatchedIsolationRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedIsolationRollup) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedIsolationRollupAttemptsRangeRule: BatchedIsolationRollupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedIsolationRollup) -> [String] {
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

    final class BatchedIsolationRollupCodePrefixRule: BatchedIsolationRollupRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedIsolationRollup) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched isolation rollup.
    final class BatchedIsolationRollupValidator {
        var rules: [any BatchedIsolationRollupRule]

        init(rules: [any BatchedIsolationRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedIsolationRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedIsolationRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedIsolationRollup]) -> [String: [String]] {
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

    static func defaultBatchedIsolationRollupValidator() -> BatchedIsolationRollupValidator {
        return BatchedIsolationRollupValidator(
            rules: [
                BatchedIsolationRollupAllowedDescriptionRule(allowed: ["strict", "default"]),
                BatchedIsolationRollupRequiredCodeRule(message: "batched isolation rollup needs this field"),
                BatchedIsolationRollupTitleLengthRule(maxLength: 32),
                BatchedIsolationRollupAttemptsRangeRule(min: 3600, max: 86400),
                BatchedIsolationRollupCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
