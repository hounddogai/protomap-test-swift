import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a batched cleaning schedule must pass. Check returns its problems, or none.
    protocol BatchedCleaningScheduleRule {
        func check(_ item: BatchedCleaningSchedule) -> [String]
    }

    final class BatchedCleaningScheduleRequiredLabelRule: BatchedCleaningScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedCleaningSchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedCleaningSchedulePinnedGuardRule: BatchedCleaningScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: BatchedCleaningSchedule) -> [String] {
            if item.pinned && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class BatchedCleaningScheduleStartsAtRangeRule: BatchedCleaningScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCleaningSchedule) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class BatchedCleaningScheduleLabelLengthRule: BatchedCleaningScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BatchedCleaningSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BatchedCleaningScheduleRetriesRangeRule: BatchedCleaningScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedCleaningSchedule) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a batched cleaning schedule.
    final class BatchedCleaningScheduleValidator {
        var rules: [any BatchedCleaningScheduleRule]

        init(rules: [any BatchedCleaningScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedCleaningSchedule) -> [String] {
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

        func requireValid(_ item: BatchedCleaningSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedCleaningSchedule]) -> [String: [String]] {
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

    static func defaultBatchedCleaningScheduleValidator() -> BatchedCleaningScheduleValidator {
        return BatchedCleaningScheduleValidator(
            rules: [
                BatchedCleaningScheduleRequiredLabelRule(message: "batched cleaning schedule needs this field"),
                BatchedCleaningSchedulePinnedGuardRule(limit: 64),
                BatchedCleaningScheduleStartsAtRangeRule(min: 32, max: 64),
                BatchedCleaningScheduleLabelLengthRule(maxLength: 64),
                BatchedCleaningScheduleRetriesRangeRule(min: 80, max: 1000),
            ]
        )
    }
}
