import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff group must pass. Check returns its problems, or none.
    protocol HandoffGroupRule {
        func check(_ item: HandoffGroup) -> [String]
    }

    final class HandoffGroupRequiredTitleRule: HandoffGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffGroupRequiredReviewerRule: HandoffGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffGroup) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffGroupAllowedSpecialtyRule: HandoffGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: HandoffGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff group.
    final class HandoffGroupValidator {
        var rules: [any HandoffGroupRule]

        init(rules: [any HandoffGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffGroup) -> [String] {
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

        func requireValid(_ item: HandoffGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffGroup]) -> [String: [String]] {
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

    static func defaultHandoffGroupValidator() -> HandoffGroupValidator {
        return HandoffGroupValidator(
            rules: [
                HandoffGroupRequiredTitleRule(message: "handoff group needs an entry"),
                HandoffGroupRequiredReviewerRule(message: "handoff group needs a value"),
                HandoffGroupAllowedSpecialtyRule(allowed: ["legacy"]),
            ]
        )
    }
}
