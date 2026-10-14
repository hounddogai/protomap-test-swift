import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction allocation must pass. Check returns its problems, or none.
    protocol InteractionAllocationRule {
        func check(_ item: InteractionAllocation) -> [String]
    }

    final class InteractionAllocationRequiredCodeRule: InteractionAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionAllocationAllowedReviewerRule: InteractionAllocationRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionAllocation) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is inconsistent"]
            }
            return []
        }
    }

    final class InteractionAllocationRequiredReviewerRule: InteractionAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionAllocation) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction allocation.
    final class InteractionAllocationValidator {
        var rules: [any InteractionAllocationRule]

        init(rules: [any InteractionAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionAllocation]) -> [String: [String]] {
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

    static func defaultInteractionAllocationValidator() -> InteractionAllocationValidator {
        return InteractionAllocationValidator(
            rules: [
                InteractionAllocationRequiredCodeRule(message: "interaction allocation needs this field"),
                InteractionAllocationAllowedReviewerRule(allowed: ["default"]),
                InteractionAllocationRequiredReviewerRule(message: "interaction allocation needs an entry"),
            ]
        )
    }
}
