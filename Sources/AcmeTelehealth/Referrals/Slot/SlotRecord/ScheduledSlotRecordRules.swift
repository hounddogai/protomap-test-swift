import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled slot record must pass. Check returns its problems, or none.
    protocol ScheduledSlotRecordRule {
        func check(_ item: ScheduledSlotRecord) -> [String]
    }

    final class ScheduledSlotRecordRequiredReviewerRule: ScheduledSlotRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledSlotRecord) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledSlotRecordCapacityRangeRule: ScheduledSlotRecordRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledSlotRecord) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledSlotRecordRequiredSummaryRule: ScheduledSlotRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledSlotRecord) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled slot record.
    final class ScheduledSlotRecordValidator {
        var rules: [any ScheduledSlotRecordRule]

        init(rules: [any ScheduledSlotRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledSlotRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledSlotRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledSlotRecord]) -> [String: [String]] {
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

    static func defaultScheduledSlotRecordValidator() -> ScheduledSlotRecordValidator {
        return ScheduledSlotRecordValidator(
            rules: [
                ScheduledSlotRecordRequiredReviewerRule(message: "scheduled slot record needs a value"),
                ScheduledSlotRecordCapacityRangeRule(min: 16, max: 80),
                ScheduledSlotRecordRequiredSummaryRule(message: "scheduled slot record needs this field"),
            ]
        )
    }
}
