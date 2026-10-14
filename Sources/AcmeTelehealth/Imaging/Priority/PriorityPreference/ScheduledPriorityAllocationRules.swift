import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled priority allocation must pass. Check returns its problems, or none.
    protocol ScheduledPriorityAllocationRule {
        func check(_ item: ScheduledPriorityAllocation) -> [String]
    }

    final class ScheduledPriorityAllocationArchivedGuardRule: ScheduledPriorityAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledPriorityAllocation) -> [String] {
            if item.archived && (item.visitMinutes > limit) {
                return ["visit minutes \(item.visitMinutes) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ScheduledPriorityAllocationBatchSizeRangeRule: ScheduledPriorityAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledPriorityAllocation) -> [String] {
            let value = item.batchSize
            var problems: [String] = []
            if value < min {
                problems.append("batch size \(value) is below \(min)")
            }
            if value > max {
                problems.append("batch size \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledPriorityAllocationRequiredCodeRule: ScheduledPriorityAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledPriorityAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledPriorityAllocationNameLengthRule: ScheduledPriorityAllocationRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledPriorityAllocation) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled priority allocation.
    final class ScheduledPriorityAllocationValidator {
        var rules: [any ScheduledPriorityAllocationRule]

        init(rules: [any ScheduledPriorityAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledPriorityAllocation) -> [String] {
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

        func requireValid(_ item: ScheduledPriorityAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledPriorityAllocation]) -> [String: [String]] {
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

    static func defaultScheduledPriorityAllocationValidator() -> ScheduledPriorityAllocationValidator {
        return ScheduledPriorityAllocationValidator(
            rules: [
                ScheduledPriorityAllocationArchivedGuardRule(limit: 64),
                ScheduledPriorityAllocationBatchSizeRangeRule(min: 255, max: 3600),
                ScheduledPriorityAllocationRequiredCodeRule(message: "scheduled priority allocation needs an entry"),
                ScheduledPriorityAllocationNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
