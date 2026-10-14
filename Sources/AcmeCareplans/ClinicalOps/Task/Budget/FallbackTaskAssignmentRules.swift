import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a fallback task assignment must pass. Check returns its problems, or none.
    protocol FallbackTaskAssignmentRule {
        func check(_ item: FallbackTaskAssignment) -> [String]
    }

    final class FallbackTaskAssignmentAllowedCodeRule: FallbackTaskAssignmentRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackTaskAssignment) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class FallbackTaskAssignmentArchivedGuardRule: FallbackTaskAssignmentRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: FallbackTaskAssignment) -> [String] {
            if item.archived && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class FallbackTaskAssignmentRequiredCodeRule: FallbackTaskAssignmentRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackTaskAssignment) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback task assignment.
    final class FallbackTaskAssignmentValidator {
        var rules: [any FallbackTaskAssignmentRule]

        init(rules: [any FallbackTaskAssignmentRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackTaskAssignment) -> [String] {
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

        func requireValid(_ item: FallbackTaskAssignment) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackTaskAssignment]) -> [String: [String]] {
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

    static func defaultFallbackTaskAssignmentValidator() -> FallbackTaskAssignmentValidator {
        return FallbackTaskAssignmentValidator(
            rules: [
                FallbackTaskAssignmentAllowedCodeRule(allowed: ["seasonal", "adaptive", "legacy"]),
                FallbackTaskAssignmentArchivedGuardRule(limit: 5.0),
                FallbackTaskAssignmentRequiredCodeRule(message: "fallback task assignment needs this field"),
            ]
        )
    }
}
