import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a lenient rounding template must pass. Check returns its problems, or none.
    protocol LenientRoundingTemplateRule {
        func check(_ item: LenientRoundingTemplate) -> [String]
    }

    final class LenientRoundingTemplateExpiresAtRangeRule: LenientRoundingTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRoundingTemplate) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientRoundingTemplateAllowedNameRule: LenientRoundingTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: LenientRoundingTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is stale"]
            }
            return []
        }
    }

    final class LenientRoundingTemplateAttemptsRangeRule: LenientRoundingTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientRoundingTemplate) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient rounding template.
    final class LenientRoundingTemplateValidator {
        var rules: [any LenientRoundingTemplateRule]

        init(rules: [any LenientRoundingTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientRoundingTemplate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientRoundingTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientRoundingTemplate]) -> [String: [String]] {
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

    static func defaultLenientRoundingTemplateValidator() -> LenientRoundingTemplateValidator {
        return LenientRoundingTemplateValidator(
            rules: [
                LenientRoundingTemplateExpiresAtRangeRule(min: 120, max: 255),
                LenientRoundingTemplateAllowedNameRule(allowed: ["batched"]),
                LenientRoundingTemplateAttemptsRangeRule(min: 1000, max: 86400),
            ]
        )
    }
}
