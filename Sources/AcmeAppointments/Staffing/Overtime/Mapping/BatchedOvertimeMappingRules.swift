import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched overtime mapping must pass. Check returns its problems, or none.
    protocol BatchedOvertimeMappingRule {
        func check(_ item: BatchedOvertimeMapping) -> [String]
    }

    final class BatchedOvertimeMappingCodePrefixRule: BatchedOvertimeMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BatchedOvertimeMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BatchedOvertimeMappingAllowedLabelRule: BatchedOvertimeMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedOvertimeMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is stale"]
            }
            return []
        }
    }

    final class BatchedOvertimeMappingCreatedAtRangeRule: BatchedOvertimeMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeMapping) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched overtime mapping.
    final class BatchedOvertimeMappingValidator {
        var rules: [any BatchedOvertimeMappingRule]

        init(rules: [any BatchedOvertimeMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOvertimeMapping) -> [String] {
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

        func requireValid(_ item: BatchedOvertimeMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOvertimeMapping]) -> [String: [String]] {
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

    static func defaultBatchedOvertimeMappingValidator() -> BatchedOvertimeMappingValidator {
        return BatchedOvertimeMappingValidator(
            rules: [
                BatchedOvertimeMappingCodePrefixRule(prefix: "Q"),
                BatchedOvertimeMappingAllowedLabelRule(allowed: ["default"]),
                BatchedOvertimeMappingCreatedAtRangeRule(min: 32, max: 120),
            ]
        )
    }
}
