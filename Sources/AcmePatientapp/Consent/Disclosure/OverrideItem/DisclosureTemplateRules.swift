import AcmePlatform
import Foundation

extension Consent {
    /// A rule a disclosure template must pass. Check returns its problems, or none.
    protocol DisclosureTemplateRule {
        func check(_ item: DisclosureTemplate) -> [String]
    }

    final class DisclosureTemplateRequiredUnitRule: DisclosureTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DisclosureTemplate) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DisclosureTemplateAllowedCodeRule: DisclosureTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: DisclosureTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class DisclosureTemplateActiveGuardRule: DisclosureTemplateRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DisclosureTemplate) -> [String] {
            if item.active && (item.quantity > limit) {
                return ["quantity \(item.quantity) exceeds \(limit) while active"]
            }
            return []
        }
    }

    /// Runs every rule of a disclosure template.
    final class DisclosureTemplateValidator {
        var rules: [any DisclosureTemplateRule]

        init(rules: [any DisclosureTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: DisclosureTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DisclosureTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DisclosureTemplate]) -> [String: [String]] {
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

    static func defaultDisclosureTemplateValidator() -> DisclosureTemplateValidator {
        return DisclosureTemplateValidator(
            rules: [
                DisclosureTemplateRequiredUnitRule(message: "disclosure template needs a value"),
                DisclosureTemplateAllowedCodeRule(allowed: ["fallback", "primary", "scheduled"]),
                DisclosureTemplateActiveGuardRule(limit: 1000),
            ]
        )
    }
}
