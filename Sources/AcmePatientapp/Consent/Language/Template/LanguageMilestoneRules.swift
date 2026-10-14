import AcmePlatform
import Foundation

extension Consent {
    /// A rule a language milestone must pass. Check returns its problems, or none.
    protocol LanguageMilestoneRule {
        func check(_ item: LanguageMilestone) -> [String]
    }

    final class LanguageMilestoneRequiredNameRule: LanguageMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageMilestone) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LanguageMilestoneAllowedNameRule: LanguageMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LanguageMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is too long"]
            }
            return []
        }
    }

    final class LanguageMilestoneVisitMinutesRangeRule: LanguageMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LanguageMilestone) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LanguageMilestoneRequiredCodeRule: LanguageMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LanguageMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a language milestone.
    final class LanguageMilestoneValidator {
        var rules: [any LanguageMilestoneRule]

        init(rules: [any LanguageMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LanguageMilestone) -> [String] {
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

        func requireValid(_ item: LanguageMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LanguageMilestone]) -> [String: [String]] {
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

    static func defaultLanguageMilestoneValidator() -> LanguageMilestoneValidator {
        return LanguageMilestoneValidator(
            rules: [
                LanguageMilestoneRequiredNameRule(message: "language milestone needs this field"),
                LanguageMilestoneAllowedNameRule(allowed: ["weighted"]),
                LanguageMilestoneVisitMinutesRangeRule(min: 16, max: 80),
                LanguageMilestoneRequiredCodeRule(message: "language milestone needs an entry"),
            ]
        )
    }
}
