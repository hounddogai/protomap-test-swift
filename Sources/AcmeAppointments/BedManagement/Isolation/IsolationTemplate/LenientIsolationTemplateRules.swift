import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a lenient isolation template must pass. Check returns its problems, or none.
    protocol LenientIsolationTemplateRule {
        func check(_ item: LenientIsolationTemplate) -> [String]
    }

    final class LenientIsolationTemplateCodePrefixRule: LenientIsolationTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientIsolationTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class LenientIsolationTemplateExpiresAtRangeRule: LenientIsolationTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientIsolationTemplate) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientIsolationTemplateRequiredCodeRule: LenientIsolationTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientIsolationTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a lenient isolation template.
    final class LenientIsolationTemplateValidator {
        var rules: [any LenientIsolationTemplateRule]

        init(rules: [any LenientIsolationTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientIsolationTemplate) -> [String] {
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

        func requireValid(_ item: LenientIsolationTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientIsolationTemplate]) -> [String: [String]] {
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

    static func defaultLenientIsolationTemplateValidator() -> LenientIsolationTemplateValidator {
        return LenientIsolationTemplateValidator(
            rules: [
                LenientIsolationTemplateCodePrefixRule(prefix: "ACM"),
                LenientIsolationTemplateExpiresAtRangeRule(min: 16, max: 1000),
                LenientIsolationTemplateRequiredCodeRule(message: "lenient isolation template needs this field"),
            ]
        )
    }
}
