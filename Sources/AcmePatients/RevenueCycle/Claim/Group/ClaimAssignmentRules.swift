import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim assignment must pass. Check returns its problems, or none.
    protocol ClaimAssignmentRule {
        func check(_ item: ClaimAssignment) -> [String]
    }

    final class ClaimAssignmentAmountRangeRule: ClaimAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ClaimAssignment) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ClaimAssignmentRequiredTitleRule: ClaimAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimAssignment) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimAssignmentRequiredSegmentRule: ClaimAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimAssignment) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a claim assignment.
    final class ClaimAssignmentValidator {
        var rules: [any ClaimAssignmentRule]

        init(rules: [any ClaimAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimAssignment) -> [String] {
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

        func requireValid(_ item: ClaimAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimAssignment]) -> [String: [String]] {
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

    static func defaultClaimAssignmentValidator() -> ClaimAssignmentValidator {
        return ClaimAssignmentValidator(
            rules: [
                ClaimAssignmentAmountRangeRule(min: 5.9, max: 2461.2),
                ClaimAssignmentRequiredTitleRule(message: "claim assignment needs this field"),
                ClaimAssignmentRequiredSegmentRule(message: "claim assignment needs an entry"),
            ]
        )
    }
}
