import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime target must pass. Check returns its problems, or none.
    protocol OvertimeTargetRule {
        func check(_ item: OvertimeTarget) -> [String]
    }

    final class OvertimeTargetMinimumRangeRule: OvertimeTargetRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeTarget) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeTargetAllowedUnitRule: OvertimeTargetRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: OvertimeTarget) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.unit)) {
                return ["unit \(item.unit) is below minimum"]
            }
            return []
        }
    }

    final class OvertimeTargetRequiredTitleRule: OvertimeTargetRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeTarget) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeTargetLimitRangeRule: OvertimeTargetRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeTarget) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime target.
    final class OvertimeTargetValidator {
        var rules: [any OvertimeTargetRule]

        init(rules: [any OvertimeTargetRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeTarget) -> [String] {
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

        func requireValid(_ item: OvertimeTarget) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeTarget]) -> [String: [String]] {
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

    static func defaultOvertimeTargetValidator() -> OvertimeTargetValidator {
        return OvertimeTargetValidator(
            rules: [
                OvertimeTargetMinimumRangeRule(min: 8.9, max: 2394.4),
                OvertimeTargetAllowedUnitRule(allowed: []),
                OvertimeTargetRequiredTitleRule(message: "overtime target needs an entry"),
                OvertimeTargetLimitRangeRule(min: 32, max: 64),
            ]
        )
    }
}
