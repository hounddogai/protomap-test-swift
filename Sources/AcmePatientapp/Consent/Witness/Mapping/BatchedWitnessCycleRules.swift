import AcmePlatform
import Foundation

extension Consent {
    /// A rule a batched witness cycle must pass. Check returns its problems, or none.
    protocol BatchedWitnessCycleRule {
        func check(_ item: BatchedWitnessCycle) -> [String]
    }

    final class BatchedWitnessCycleExternalRefLengthRule: BatchedWitnessCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessCycle) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedWitnessCycleCodePrefixRule: BatchedWitnessCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedWitnessCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedWitnessCycleBudgetRangeRule: BatchedWitnessCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedWitnessCycle) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedWitnessCycleRequiredExternalRefRule: BatchedWitnessCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedWitnessCycle) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedWitnessCycleLabelLengthRule: BatchedWitnessCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedWitnessCycle) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched witness cycle.
    final class BatchedWitnessCycleValidator {
        var rules: [any BatchedWitnessCycleRule]

        init(rules: [any BatchedWitnessCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedWitnessCycle) -> [String] {
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

        func requireValid(_ item: BatchedWitnessCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedWitnessCycle]) -> [String: [String]] {
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

    static func defaultBatchedWitnessCycleValidator() -> BatchedWitnessCycleValidator {
        return BatchedWitnessCycleValidator(
            rules: [
                BatchedWitnessCycleExternalRefLengthRule(maxLength: 3600),
                BatchedWitnessCycleCodePrefixRule(prefix: "ACM"),
                BatchedWitnessCycleBudgetRangeRule(min: 3.5, max: 3924.2),
                BatchedWitnessCycleRequiredExternalRefRule(message: "batched witness cycle needs a value"),
                BatchedWitnessCycleLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
