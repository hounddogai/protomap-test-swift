import AcmePlatform
import Foundation

extension Consent {
    /// A rule a witness override must pass. Check returns its problems, or none.
    protocol WitnessOverrideRule {
        func check(_ item: WitnessOverride) -> [String]
    }

    final class WitnessOverrideRequiredWardRule: WitnessOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessOverride) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessOverrideRequiredTitleRule: WitnessOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WitnessOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WitnessOverrideTitleLengthRule: WitnessOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WitnessOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WitnessOverrideAllowedCodeRule: WitnessOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: WitnessOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is below minimum"]
            }
            return []
        }
    }

    /// Runs every rule of a witness override.
    final class WitnessOverrideValidator {
        var rules: [any WitnessOverrideRule]

        init(rules: [any WitnessOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: WitnessOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WitnessOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WitnessOverride]) -> [String: [String]] {
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

    static func defaultWitnessOverrideValidator() -> WitnessOverrideValidator {
        return WitnessOverrideValidator(
            rules: [
                WitnessOverrideRequiredWardRule(message: "witness override needs an entry"),
                WitnessOverrideRequiredTitleRule(message: "witness override needs a value"),
                WitnessOverrideTitleLengthRule(maxLength: 3600),
                WitnessOverrideAllowedCodeRule(allowed: []),
            ]
        )
    }
}
