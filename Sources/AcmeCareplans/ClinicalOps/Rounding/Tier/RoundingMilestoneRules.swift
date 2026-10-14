import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding milestone must pass. Check returns its problems, or none.
    protocol RoundingMilestoneRule {
        func check(_ item: RoundingMilestone) -> [String]
    }

    final class RoundingMilestoneRequiredLabelRule: RoundingMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingMilestone) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingMilestoneAllowedContactEmailRule: RoundingMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RoundingMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is inconsistent"]
            }
            return []
        }
    }

    final class RoundingMilestoneRequiredCodeRule: RoundingMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rounding milestone.
    final class RoundingMilestoneValidator {
        var rules: [any RoundingMilestoneRule]

        init(rules: [any RoundingMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingMilestone) -> [String] {
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

        func requireValid(_ item: RoundingMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingMilestone]) -> [String: [String]] {
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

    static func defaultRoundingMilestoneValidator() -> RoundingMilestoneValidator {
        return RoundingMilestoneValidator(
            rules: [
                RoundingMilestoneRequiredLabelRule(message: "rounding milestone needs a value"),
                RoundingMilestoneAllowedContactEmailRule(allowed: []),
                RoundingMilestoneRequiredCodeRule(message: "rounding milestone needs a value"),
            ]
        )
    }
}
