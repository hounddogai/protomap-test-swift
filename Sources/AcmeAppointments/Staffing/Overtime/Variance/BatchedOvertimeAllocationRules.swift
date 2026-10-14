import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a batched overtime allocation must pass. Check returns its problems, or none.
    protocol BatchedOvertimeAllocationRule {
        func check(_ item: BatchedOvertimeAllocation) -> [String]
    }

    final class BatchedOvertimeAllocationFloorValueRangeRule: BatchedOvertimeAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeAllocation) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedOvertimeAllocationWeightRangeRule: BatchedOvertimeAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeAllocation) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedOvertimeAllocationEndsAtRangeRule: BatchedOvertimeAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedOvertimeAllocation) -> [String] {
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

    final class BatchedOvertimeAllocationAllowedTitleRule: BatchedOvertimeAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BatchedOvertimeAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is missing"]
            }
            return []
        }
    }

    final class BatchedOvertimeAllocationRequiredTitleRule: BatchedOvertimeAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedOvertimeAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched overtime allocation.
    final class BatchedOvertimeAllocationValidator {
        var rules: [any BatchedOvertimeAllocationRule]

        init(rules: [any BatchedOvertimeAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedOvertimeAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedOvertimeAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedOvertimeAllocation]) -> [String: [String]] {
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

    static func defaultBatchedOvertimeAllocationValidator() -> BatchedOvertimeAllocationValidator {
        return BatchedOvertimeAllocationValidator(
            rules: [
                BatchedOvertimeAllocationFloorValueRangeRule(min: 2.8, max: 4928.6),
                BatchedOvertimeAllocationWeightRangeRule(min: 4.0, max: 1617.9),
                BatchedOvertimeAllocationEndsAtRangeRule(min: 120, max: 120),
                BatchedOvertimeAllocationAllowedTitleRule(allowed: []),
                BatchedOvertimeAllocationRequiredTitleRule(message: "batched overtime allocation needs an entry"),
            ]
        )
    }
}
