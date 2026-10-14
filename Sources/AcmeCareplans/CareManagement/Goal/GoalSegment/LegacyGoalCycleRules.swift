import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy goal cycle must pass. Check returns its problems, or none.
    protocol LegacyGoalCycleRule {
        func check(_ item: LegacyGoalCycle) -> [String]
    }

    final class LegacyGoalCycleRequiredWardRule: LegacyGoalCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyGoalCycle) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyGoalCycleStartsAtRangeRule: LegacyGoalCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyGoalCycle) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyGoalCycleFloorValueRangeRule: LegacyGoalCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyGoalCycle) -> [String] {
            let value = item.floorValue
            if value < min || value > max {
                return ["floor value \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyGoalCycleRequiredCodeRule: LegacyGoalCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyGoalCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy goal cycle.
    final class LegacyGoalCycleValidator {
        var rules: [any LegacyGoalCycleRule]

        init(rules: [any LegacyGoalCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyGoalCycle) -> [String] {
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

        func requireValid(_ item: LegacyGoalCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyGoalCycle]) -> [String: [String]] {
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

    static func defaultLegacyGoalCycleValidator() -> LegacyGoalCycleValidator {
        return LegacyGoalCycleValidator(
            rules: [
                LegacyGoalCycleRequiredWardRule(message: "legacy goal cycle needs this field"),
                LegacyGoalCycleStartsAtRangeRule(min: 255, max: 86400),
                LegacyGoalCycleFloorValueRangeRule(min: 4.1, max: 825.5),
                LegacyGoalCycleRequiredCodeRule(message: "legacy goal cycle needs an entry"),
            ]
        )
    }
}
