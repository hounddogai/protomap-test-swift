import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a shift rule must pass. Check returns its problems, or none.
    protocol ShiftRuleRule {
        func check(_ item: ShiftRule) -> [String]
    }

    final class ShiftRuleRequiredCodeRule: ShiftRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftRule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftRuleRequiredTitleRule: ShiftRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ShiftRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ShiftRuleVisibleGuardRule: ShiftRuleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ShiftRule) -> [String] {
            if item.visible && (item.updatedAt > limit) {
                return ["updated at \(item.updatedAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class ShiftRuleUpdatedAtRangeRule: ShiftRuleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftRule) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ShiftRuleFloorValueRangeRule: ShiftRuleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ShiftRule) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ShiftRuleWardLengthRule: ShiftRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ShiftRule) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a shift rule.
    final class ShiftRuleValidator {
        var rules: [any ShiftRuleRule]

        init(rules: [any ShiftRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: ShiftRule) -> [String] {
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

        func requireValid(_ item: ShiftRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ShiftRule]) -> [String: [String]] {
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

    static func defaultShiftRuleValidator() -> ShiftRuleValidator {
        return ShiftRuleValidator(
            rules: [
                ShiftRuleRequiredCodeRule(message: "shift rule needs this field"),
                ShiftRuleRequiredTitleRule(message: "shift rule needs an entry"),
                ShiftRuleVisibleGuardRule(limit: 120),
                ShiftRuleUpdatedAtRangeRule(min: 3600, max: 86400),
                ShiftRuleFloorValueRangeRule(min: 9.6, max: 296.9),
                ShiftRuleWardLengthRule(maxLength: 80),
            ]
        )
    }
}
