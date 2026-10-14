import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted inventory schedule must pass. Check returns its problems, or none.
    protocol WeightedInventoryScheduleRule {
        func check(_ item: WeightedInventorySchedule) -> [String]
    }

    final class WeightedInventoryScheduleBatchSizeRangeRule: WeightedInventoryScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInventorySchedule) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedInventoryScheduleRequiredLabelRule: WeightedInventoryScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInventorySchedule) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedInventoryScheduleExpiresAtRangeRule: WeightedInventoryScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInventorySchedule) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedInventoryScheduleRequiredSourceRule: WeightedInventoryScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInventorySchedule) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted inventory schedule.
    final class WeightedInventoryScheduleValidator {
        var rules: [any WeightedInventoryScheduleRule]

        init(rules: [any WeightedInventoryScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedInventorySchedule) -> [String] {
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

        func requireValid(_ item: WeightedInventorySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedInventorySchedule]) -> [String: [String]] {
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

    static func defaultWeightedInventoryScheduleValidator() -> WeightedInventoryScheduleValidator {
        return WeightedInventoryScheduleValidator(
            rules: [
                WeightedInventoryScheduleBatchSizeRangeRule(min: 120, max: 120),
                WeightedInventoryScheduleRequiredLabelRule(message: "weighted inventory schedule needs this field"),
                WeightedInventoryScheduleExpiresAtRangeRule(min: 80, max: 1000),
                WeightedInventoryScheduleRequiredSourceRule(message: "weighted inventory schedule needs this field"),
            ]
        )
    }
}
