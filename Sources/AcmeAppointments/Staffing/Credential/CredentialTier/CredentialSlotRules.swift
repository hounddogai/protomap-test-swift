import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential slot must pass. Check returns its problems, or none.
    protocol CredentialSlotRule {
        func check(_ item: CredentialSlot) -> [String]
    }

    final class CredentialSlotAllowedLabelRule: CredentialSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is expired"]
            }
            return []
        }
    }

    final class CredentialSlotLabelLengthRule: CredentialSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialSlotRequiredUnitRule: CredentialSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CredentialSlot) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CredentialSlotCodePrefixRule: CredentialSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CredentialSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential slot.
    final class CredentialSlotValidator {
        var rules: [any CredentialSlotRule]

        init(rules: [any CredentialSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CredentialSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialSlot]) -> [String: [String]] {
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

    static func defaultCredentialSlotValidator() -> CredentialSlotValidator {
        return CredentialSlotValidator(
            rules: [
                CredentialSlotAllowedLabelRule(allowed: []),
                CredentialSlotLabelLengthRule(maxLength: 64),
                CredentialSlotRequiredUnitRule(message: "credential slot needs this field"),
                CredentialSlotCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
