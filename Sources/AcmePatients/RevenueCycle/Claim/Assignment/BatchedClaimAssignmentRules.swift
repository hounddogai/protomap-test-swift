import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a batched claim assignment must pass. Check returns its problems, or none.
    protocol BatchedClaimAssignmentRule {
        func check(_ item: BatchedClaimAssignment) -> [String]
    }

    final class BatchedClaimAssignmentCodeLengthRule: BatchedClaimAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedClaimAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedClaimAssignmentGraceDaysRangeRule: BatchedClaimAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClaimAssignment) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedClaimAssignmentWindowDaysRangeRule: BatchedClaimAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedClaimAssignment) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched claim assignment.
    final class BatchedClaimAssignmentValidator {
        var rules: [any BatchedClaimAssignmentRule]

        init(rules: [any BatchedClaimAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedClaimAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: BatchedClaimAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedClaimAssignment]) -> [String: [String]] {
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

    static func defaultBatchedClaimAssignmentValidator() -> BatchedClaimAssignmentValidator {
        return BatchedClaimAssignmentValidator(
            rules: [
                BatchedClaimAssignmentCodeLengthRule(maxLength: 255),
                BatchedClaimAssignmentGraceDaysRangeRule(min: 80, max: 1000),
                BatchedClaimAssignmentWindowDaysRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
