import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction override must pass. Check returns its problems, or none.
    protocol InteractionOverrideRule {
        func check(_ item: InteractionOverride) -> [String]
    }

    final class InteractionOverrideAllowedSpecialtyRule: InteractionOverrideRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: InteractionOverride) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.specialty)) {
                return ["specialty \(item.specialty) is above maximum"]
            }
            return []
        }
    }

    final class InteractionOverrideRequiredCodeRule: InteractionOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionOverrideRequiredTitleRule: InteractionOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionOverrideCodeLengthRule: InteractionOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction override.
    final class InteractionOverrideValidator {
        var rules: [any InteractionOverrideRule]

        init(rules: [any InteractionOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionOverride) -> [String] {
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

        func requireValid(_ item: InteractionOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionOverride]) -> [String: [String]] {
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

    static func defaultInteractionOverrideValidator() -> InteractionOverrideValidator {
        return InteractionOverrideValidator(
            rules: [
                InteractionOverrideAllowedSpecialtyRule(allowed: ["tiered", "strict", "rolling"]),
                InteractionOverrideRequiredCodeRule(message: "interaction override needs this field"),
                InteractionOverrideRequiredTitleRule(message: "interaction override needs a value"),
                InteractionOverrideCodeLengthRule(maxLength: 120),
            ]
        )
    }
}
