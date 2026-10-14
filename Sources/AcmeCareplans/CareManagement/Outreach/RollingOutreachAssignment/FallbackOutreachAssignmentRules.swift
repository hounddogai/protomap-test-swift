import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a fallback outreach assignment must pass. Check returns its problems, or none.
    protocol FallbackOutreachAssignmentRule {
        func check(_ item: FallbackOutreachAssignment) -> [String]
    }

    final class FallbackOutreachAssignmentQuantityRangeRule: FallbackOutreachAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOutreachAssignment) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FallbackOutreachAssignmentAcuityRangeRule: FallbackOutreachAssignmentRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackOutreachAssignment) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackOutreachAssignmentRequiredSegmentRule: FallbackOutreachAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOutreachAssignment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackOutreachAssignmentRequiredCodeRule: FallbackOutreachAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackOutreachAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback outreach assignment.
    final class FallbackOutreachAssignmentValidator {
        var rules: [any FallbackOutreachAssignmentRule]

        init(rules: [any FallbackOutreachAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackOutreachAssignment) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackOutreachAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackOutreachAssignment]) -> [String: [String]] {
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

    static func defaultFallbackOutreachAssignmentValidator() -> FallbackOutreachAssignmentValidator {
        return FallbackOutreachAssignmentValidator(
            rules: [
                FallbackOutreachAssignmentQuantityRangeRule(min: 255, max: 3600),
                FallbackOutreachAssignmentAcuityRangeRule(min: 64, max: 3600),
                FallbackOutreachAssignmentRequiredSegmentRule(message: "fallback outreach assignment needs an entry"),
                FallbackOutreachAssignmentRequiredCodeRule(message: "fallback outreach assignment needs a value"),
            ]
        )
    }
}
