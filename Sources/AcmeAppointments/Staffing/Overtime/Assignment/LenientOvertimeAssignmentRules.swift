import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a lenient overtime assignment must pass. Check returns its problems, or none.
    protocol LenientOvertimeAssignmentRule {
        func check(_ item: LenientOvertimeAssignment) -> [String]
    }

    final class LenientOvertimeAssignmentWeightRangeRule: LenientOvertimeAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOvertimeAssignment) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LenientOvertimeAssignmentMarginRangeRule: LenientOvertimeAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientOvertimeAssignment) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientOvertimeAssignmentTitleLengthRule: LenientOvertimeAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOvertimeAssignment) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient overtime assignment.
    final class LenientOvertimeAssignmentValidator {
        var rules: [any LenientOvertimeAssignmentRule]

        init(rules: [any LenientOvertimeAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOvertimeAssignment) -> [String] {
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

        func requireValid(_ item: LenientOvertimeAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOvertimeAssignment]) -> [String: [String]] {
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

    static func defaultLenientOvertimeAssignmentValidator() -> LenientOvertimeAssignmentValidator {
        return LenientOvertimeAssignmentValidator(
            rules: [
                LenientOvertimeAssignmentWeightRangeRule(min: 8.5, max: 1448.6),
                LenientOvertimeAssignmentMarginRangeRule(min: 2.5, max: 109.6),
                LenientOvertimeAssignmentTitleLengthRule(maxLength: 16),
            ]
        )
    }
}
