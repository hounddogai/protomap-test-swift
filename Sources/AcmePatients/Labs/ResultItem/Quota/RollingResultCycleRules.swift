import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling result cycle must pass. Check returns its problems, or none.
    protocol RollingResultCycleRule {
        func check(_ item: RollingResultCycle) -> [String]
    }

    final class RollingResultCycleRequiredDescriptionRule: RollingResultCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingResultCycle) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingResultCycleCostRangeRule: RollingResultCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingResultCycle) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingResultCycleCreatedAtRangeRule: RollingResultCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingResultCycle) -> [String] {
            let value = item.createdAt
            if value < min || value > max {
                return ["created at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RollingResultCycleCopayRangeRule: RollingResultCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingResultCycle) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingResultCycleDescriptionLengthRule: RollingResultCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultCycle) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingResultCycleWardLengthRule: RollingResultCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingResultCycle) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling result cycle.
    final class RollingResultCycleValidator {
        var rules: [any RollingResultCycleRule]

        init(rules: [any RollingResultCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingResultCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingResultCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingResultCycle]) -> [String: [String]] {
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

    static func defaultRollingResultCycleValidator() -> RollingResultCycleValidator {
        return RollingResultCycleValidator(
            rules: [
                RollingResultCycleRequiredDescriptionRule(message: "rolling result cycle needs a value"),
                RollingResultCycleCostRangeRule(min: 3.1, max: 1730.8),
                RollingResultCycleCreatedAtRangeRule(min: 16, max: 86400),
                RollingResultCycleCopayRangeRule(min: 8.4, max: 1386.2),
                RollingResultCycleDescriptionLengthRule(maxLength: 120),
                RollingResultCycleWardLengthRule(maxLength: 1000),
            ]
        )
    }
}
