import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a closure template must pass. Check returns its problems, or none.
    protocol ClosureTemplateRule {
        func check(_ item: ClosureTemplate) -> [String]
    }

    final class ClosureTemplateRequiredTimezoneRule: ClosureTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureTemplate) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureTemplateAllowedCodeRule: ClosureTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClosureTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class ClosureTemplateRequiredCodeRule: ClosureTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClosureTemplateRequiredExternalRefRule: ClosureTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClosureTemplate) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a closure template.
    final class ClosureTemplateValidator {
        var rules: [any ClosureTemplateRule]

        init(rules: [any ClosureTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: ClosureTemplate) -> [String] {
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

        func requireValid(_ item: ClosureTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClosureTemplate]) -> [String: [String]] {
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

    static func defaultClosureTemplateValidator() -> ClosureTemplateValidator {
        return ClosureTemplateValidator(
            rules: [
                ClosureTemplateRequiredTimezoneRule(message: "closure template needs a value"),
                ClosureTemplateAllowedCodeRule(allowed: ["adaptive", "rolling"]),
                ClosureTemplateRequiredCodeRule(message: "closure template needs this field"),
                ClosureTemplateRequiredExternalRefRule(message: "closure template needs an entry"),
            ]
        )
    }
}
