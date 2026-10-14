import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive priority milestone must pass. Check returns its problems, or none.
    protocol AdaptivePriorityMilestoneRule {
        func check(_ item: AdaptivePriorityMilestone) -> [String]
    }

    final class AdaptivePriorityMilestoneAllowedContactEmailRule: AdaptivePriorityMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AdaptivePriorityMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is out of range"]
            }
            return []
        }
    }

    final class AdaptivePriorityMilestoneRequiredCodeRule: AdaptivePriorityMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptivePriorityMilestoneRequiredContactEmailRule: AdaptivePriorityMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptivePriorityMilestone) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive priority milestone.
    final class AdaptivePriorityMilestoneValidator {
        var rules: [any AdaptivePriorityMilestoneRule]

        init(rules: [any AdaptivePriorityMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptivePriorityMilestone) -> [String] {
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

        func requireValid(_ item: AdaptivePriorityMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptivePriorityMilestone]) -> [String: [String]] {
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

    static func defaultAdaptivePriorityMilestoneValidator() -> AdaptivePriorityMilestoneValidator {
        return AdaptivePriorityMilestoneValidator(
            rules: [
                AdaptivePriorityMilestoneAllowedContactEmailRule(allowed: []),
                AdaptivePriorityMilestoneRequiredCodeRule(message: "adaptive priority milestone needs a value"),
                AdaptivePriorityMilestoneRequiredContactEmailRule(
                    message: "adaptive priority milestone needs this field"
                ),
            ]
        )
    }
}
