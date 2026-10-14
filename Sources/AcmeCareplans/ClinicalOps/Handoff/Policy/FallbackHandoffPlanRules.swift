import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback handoff plan must pass. Check returns its problems, or none.
    protocol FallbackHandoffPlanRule {
        func check(_ item: FallbackHandoffPlan) -> [String]
    }

    final class FallbackHandoffPlanRequiredCodeRule: FallbackHandoffPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackHandoffPlan) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackHandoffPlanRequiredSegmentRule: FallbackHandoffPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackHandoffPlan) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackHandoffPlanRequiredOwnerIDRule: FallbackHandoffPlanRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackHandoffPlan) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback handoff plan.
    final class FallbackHandoffPlanValidator {
        var rules: [any FallbackHandoffPlanRule]

        init(rules: [any FallbackHandoffPlanRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackHandoffPlan) -> [String] {
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

        func requireValid(_ item: FallbackHandoffPlan) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackHandoffPlan]) -> [String: [String]] {
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

    static func defaultFallbackHandoffPlanValidator() -> FallbackHandoffPlanValidator {
        return FallbackHandoffPlanValidator(
            rules: [
                FallbackHandoffPlanRequiredCodeRule(message: "fallback handoff plan needs a value"),
                FallbackHandoffPlanRequiredSegmentRule(message: "fallback handoff plan needs this field"),
                FallbackHandoffPlanRequiredOwnerIDRule(message: "fallback handoff plan needs a value"),
            ]
        )
    }
}
