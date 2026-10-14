import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a fallback skill mix rollup must pass. Check returns its problems, or none.
    protocol FallbackSkillMixRollupRule {
        func check(_ item: FallbackSkillMixRollup) -> [String]
    }

    final class FallbackSkillMixRollupRequiredNameRule: FallbackSkillMixRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSkillMixRollup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackSkillMixRollupExternalRefLengthRule: FallbackSkillMixRollupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackSkillMixRollup) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackSkillMixRollupRequiredExternalRefRule: FallbackSkillMixRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSkillMixRollup) -> [String] {
            if item.externalRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackSkillMixRollupAllowedCodeRule: FallbackSkillMixRollupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackSkillMixRollup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is duplicated"]
            }
            return []
        }
    }

    final class FallbackSkillMixRollupRequiredCodeRule: FallbackSkillMixRollupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackSkillMixRollup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback skill mix rollup.
    final class FallbackSkillMixRollupValidator {
        var rules: [any FallbackSkillMixRollupRule]

        init(rules: [any FallbackSkillMixRollupRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackSkillMixRollup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackSkillMixRollup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackSkillMixRollup]) -> [String: [String]] {
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

    static func defaultFallbackSkillMixRollupValidator() -> FallbackSkillMixRollupValidator {
        return FallbackSkillMixRollupValidator(
            rules: [
                FallbackSkillMixRollupRequiredNameRule(message: "fallback skill mix rollup needs a value"),
                FallbackSkillMixRollupExternalRefLengthRule(maxLength: 255),
                FallbackSkillMixRollupRequiredExternalRefRule(message: "fallback skill mix rollup needs an entry"),
                FallbackSkillMixRollupAllowedCodeRule(allowed: ["primary", "capped"]),
                FallbackSkillMixRollupRequiredCodeRule(message: "fallback skill mix rollup needs an entry"),
            ]
        )
    }
}
