import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched cleaning cycle must pass. Check returns its problems, or none.
    protocol BatchedCleaningCycleRule {
        func check(_ item: BatchedCleaningCycle) -> [String]
    }

    final class BatchedCleaningCycleMaximumRangeRule: BatchedCleaningCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCleaningCycle) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCleaningCycleCodeLengthRule: BatchedCleaningCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCleaningCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCleaningCycleAllowedCodeRule: BatchedCleaningCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedCleaningCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class BatchedCleaningCyclePriorityRangeRule: BatchedCleaningCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCleaningCycle) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCleaningCycleCodePrefixRule: BatchedCleaningCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedCleaningCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched cleaning cycle.
    final class BatchedCleaningCycleValidator {
        var rules: [any BatchedCleaningCycleRule]

        init(rules: [any BatchedCleaningCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCleaningCycle) -> [String] {
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

        func requireValid(_ item: BatchedCleaningCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCleaningCycle]) -> [String: [String]] {
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

    static func defaultBatchedCleaningCycleValidator() -> BatchedCleaningCycleValidator {
        return BatchedCleaningCycleValidator(
            rules: [
                BatchedCleaningCycleMaximumRangeRule(min: 3.2, max: 4664.6),
                BatchedCleaningCycleCodeLengthRule(maxLength: 3600),
                BatchedCleaningCycleAllowedCodeRule(allowed: ["pending", "default", "rolling"]),
                BatchedCleaningCyclePriorityRangeRule(min: 1000, max: 86400),
                BatchedCleaningCycleCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
