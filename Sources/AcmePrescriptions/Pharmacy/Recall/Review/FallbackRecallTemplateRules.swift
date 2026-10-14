import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a fallback recall template must pass. Check returns its problems, or none.
    protocol FallbackRecallTemplateRule {
        func check(_ item: FallbackRecallTemplate) -> [String]
    }

    final class FallbackRecallTemplateEndsAtRangeRule: FallbackRecallTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FallbackRecallTemplate) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FallbackRecallTemplateCodePrefixRule: FallbackRecallTemplateRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackRecallTemplate) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackRecallTemplateAllowedCodeRule: FallbackRecallTemplateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackRecallTemplate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class FallbackRecallTemplateRequiredCodeRule: FallbackRecallTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackRecallTemplate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackRecallTemplateCodeLengthRule: FallbackRecallTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackRecallTemplate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback recall template.
    final class FallbackRecallTemplateValidator {
        var rules: [any FallbackRecallTemplateRule]

        init(rules: [any FallbackRecallTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackRecallTemplate) -> [String] {
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

        func requireValid(_ item: FallbackRecallTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackRecallTemplate]) -> [String: [String]] {
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

    static func defaultFallbackRecallTemplateValidator() -> FallbackRecallTemplateValidator {
        return FallbackRecallTemplateValidator(
            rules: [
                FallbackRecallTemplateEndsAtRangeRule(min: 120, max: 86400),
                FallbackRecallTemplateCodePrefixRule(prefix: "REF"),
                FallbackRecallTemplateAllowedCodeRule(allowed: ["weighted", "seasonal", "batched"]),
                FallbackRecallTemplateRequiredCodeRule(message: "fallback recall template needs a value"),
                FallbackRecallTemplateCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
