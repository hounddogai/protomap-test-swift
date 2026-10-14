import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled worklist adjustment must pass. Check returns its problems, or none.
    protocol ScheduledWorklistAdjustmentRule {
        func check(_ item: ScheduledWorklistAdjustment) -> [String]
    }

    final class ScheduledWorklistAdjustmentCopayRangeRule: ScheduledWorklistAdjustmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledWorklistAdjustment) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledWorklistAdjustmentRequiredUnitRule: ScheduledWorklistAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWorklistAdjustment) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledWorklistAdjustmentRequiredLabelRule: ScheduledWorklistAdjustmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWorklistAdjustment) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledWorklistAdjustmentUnitLengthRule: ScheduledWorklistAdjustmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledWorklistAdjustment) -> [String] {
            let size = item.unit.count
            if size > maxLength {
                return ["unit is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled worklist adjustment.
    final class ScheduledWorklistAdjustmentValidator {
        var rules: [any ScheduledWorklistAdjustmentRule]

        init(rules: [any ScheduledWorklistAdjustmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledWorklistAdjustment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledWorklistAdjustment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledWorklistAdjustment]) -> [String: [String]] {
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

    static func defaultScheduledWorklistAdjustmentValidator() -> ScheduledWorklistAdjustmentValidator {
        return ScheduledWorklistAdjustmentValidator(
            rules: [
                ScheduledWorklistAdjustmentCopayRangeRule(min: 8.6, max: 1288.6),
                ScheduledWorklistAdjustmentRequiredUnitRule(message: "scheduled worklist adjustment needs this field"),
                ScheduledWorklistAdjustmentRequiredLabelRule(message: "scheduled worklist adjustment needs a value"),
                ScheduledWorklistAdjustmentUnitLengthRule(maxLength: 80),
            ]
        )
    }
}
