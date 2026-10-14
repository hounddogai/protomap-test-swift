import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff mapping must pass. Check returns its problems, or none.
    protocol HandoffMappingRule {
        func check(_ item: HandoffMapping) -> [String]
    }

    final class HandoffMappingRequiredCodeRule: HandoffMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffMapping) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffMappingAllowedReviewerRule: HandoffMappingRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffMapping) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is expired"]
            }
            return []
        }
    }

    final class HandoffMappingArchivedGuardRule: HandoffMappingRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: HandoffMapping) -> [String] {
            if item.archived && (item.expiresAt > limit) {
                return ["expires at \(item.expiresAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class HandoffMappingExpiresAtRangeRule: HandoffMappingRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffMapping) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a handoff mapping.
    final class HandoffMappingValidator {
        var rules: [any HandoffMappingRule]

        init(rules: [any HandoffMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffMapping) -> [String] {
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

        func requireValid(_ item: HandoffMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffMapping]) -> [String: [String]] {
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

    static func defaultHandoffMappingValidator() -> HandoffMappingValidator {
        return HandoffMappingValidator(
            rules: [
                HandoffMappingRequiredCodeRule(message: "handoff mapping needs this field"),
                HandoffMappingAllowedReviewerRule(allowed: ["strict", "seasonal", "global"]),
                HandoffMappingArchivedGuardRule(limit: 120),
                HandoffMappingExpiresAtRangeRule(min: 32, max: 80),
            ]
        )
    }
}
