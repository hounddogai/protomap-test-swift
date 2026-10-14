import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a authorization slot must pass. Check returns its problems, or none.
    protocol AuthorizationSlotRule {
        func check(_ item: AuthorizationSlot) -> [String]
    }

    final class AuthorizationSlotAllowedPayerRule: AuthorizationSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: AuthorizationSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is inconsistent"]
            }
            return []
        }
    }

    final class AuthorizationSlotRequiredPayerRule: AuthorizationSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationSlot) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationSlotRequiredCodeRule: AuthorizationSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AuthorizationSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AuthorizationSlotPayerLengthRule: AuthorizationSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AuthorizationSlot) -> [String] {
            let size = item.payer.count
            if size > maxLength {
                return ["payer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a authorization slot.
    final class AuthorizationSlotValidator {
        var rules: [any AuthorizationSlotRule]

        init(rules: [any AuthorizationSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: AuthorizationSlot) -> [String] {
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

        func requireValid(_ item: AuthorizationSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AuthorizationSlot]) -> [String: [String]] {
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

    static func defaultAuthorizationSlotValidator() -> AuthorizationSlotValidator {
        return AuthorizationSlotValidator(
            rules: [
                AuthorizationSlotAllowedPayerRule(allowed: ["capped", "primary"]),
                AuthorizationSlotRequiredPayerRule(message: "authorization slot needs a value"),
                AuthorizationSlotRequiredCodeRule(message: "authorization slot needs this field"),
                AuthorizationSlotPayerLengthRule(maxLength: 64),
            ]
        )
    }
}
