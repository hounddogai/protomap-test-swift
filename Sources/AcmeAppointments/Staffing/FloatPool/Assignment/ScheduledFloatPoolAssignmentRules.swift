import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a scheduled float pool assignment must pass. Check returns its problems, or none.
    protocol ScheduledFloatPoolAssignmentRule {
        func check(_ item: ScheduledFloatPoolAssignment) -> [String]
    }

    final class ScheduledFloatPoolAssignmentDiscountRangeRule: ScheduledFloatPoolAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFloatPoolAssignment) -> [String] {
            let value = item.discount
            if value < min || value > max {
                return ["discount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolAssignmentCodePrefixRule: ScheduledFloatPoolAssignmentRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledFloatPoolAssignment) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolAssignmentCodeLengthRule: ScheduledFloatPoolAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFloatPoolAssignment) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFloatPoolAssignmentThresholdRangeRule: ScheduledFloatPoolAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFloatPoolAssignment) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled float pool assignment.
    final class ScheduledFloatPoolAssignmentValidator {
        var rules: [any ScheduledFloatPoolAssignmentRule]

        init(rules: [any ScheduledFloatPoolAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFloatPoolAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledFloatPoolAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFloatPoolAssignment]) -> [String: [String]] {
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

    static func defaultScheduledFloatPoolAssignmentValidator() -> ScheduledFloatPoolAssignmentValidator {
        return ScheduledFloatPoolAssignmentValidator(
            rules: [
                ScheduledFloatPoolAssignmentDiscountRangeRule(min: 5.0, max: 1011.6),
                ScheduledFloatPoolAssignmentCodePrefixRule(prefix: "X"),
                ScheduledFloatPoolAssignmentCodeLengthRule(maxLength: 64),
                ScheduledFloatPoolAssignmentThresholdRangeRule(min: 1.4, max: 4138.6),
            ]
        )
    }
}
