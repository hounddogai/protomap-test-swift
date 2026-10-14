import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a weighted follow up assignment must pass. Check returns its problems, or none.
    protocol WeightedFollowUpAssignmentRule {
        func check(_ item: WeightedFollowUpAssignment) -> [String]
    }

    final class WeightedFollowUpAssignmentCopayRangeRule: WeightedFollowUpAssignmentRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFollowUpAssignment) -> [String] {
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

    final class WeightedFollowUpAssignmentAllowedLabelRule: WeightedFollowUpAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WeightedFollowUpAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is above maximum"]
            }
            return []
        }
    }

    final class WeightedFollowUpAssignmentSourceLengthRule: WeightedFollowUpAssignmentRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFollowUpAssignment) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted follow up assignment.
    final class WeightedFollowUpAssignmentValidator {
        var rules: [any WeightedFollowUpAssignmentRule]

        init(rules: [any WeightedFollowUpAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFollowUpAssignment) -> [String] {
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

        func requireValid(_ item: WeightedFollowUpAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFollowUpAssignment]) -> [String: [String]] {
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

    static func defaultWeightedFollowUpAssignmentValidator() -> WeightedFollowUpAssignmentValidator {
        return WeightedFollowUpAssignmentValidator(
            rules: [
                WeightedFollowUpAssignmentCopayRangeRule(min: 3.1, max: 2437.5),
                WeightedFollowUpAssignmentAllowedLabelRule(allowed: ["regional"]),
                WeightedFollowUpAssignmentSourceLengthRule(maxLength: 16),
            ]
        )
    }
}
