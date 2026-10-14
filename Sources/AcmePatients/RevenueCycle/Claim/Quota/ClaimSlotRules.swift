import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a claim slot must pass. Check returns its problems, or none.
    protocol ClaimSlotRule {
        func check(_ item: ClaimSlot) -> [String]
    }

    final class ClaimSlotCodePrefixRule: ClaimSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ClaimSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ClaimSlotCodeLengthRule: ClaimSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimSlotAllowedTimezoneRule: ClaimSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ClaimSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.timezone)) {
                return ["timezone \(item.timezone) is expired"]
            }
            return []
        }
    }

    final class ClaimSlotTimezoneLengthRule: ClaimSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimSlot) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ClaimSlotRequiredCodeRule: ClaimSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ClaimSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ClaimSlotLabelLengthRule: ClaimSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ClaimSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a claim slot.
    final class ClaimSlotValidator {
        var rules: [any ClaimSlotRule]

        init(rules: [any ClaimSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ClaimSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ClaimSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ClaimSlot]) -> [String: [String]] {
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

    static func defaultClaimSlotValidator() -> ClaimSlotValidator {
        return ClaimSlotValidator(
            rules: [
                ClaimSlotCodePrefixRule(prefix: "ACM"),
                ClaimSlotCodeLengthRule(maxLength: 16),
                ClaimSlotAllowedTimezoneRule(allowed: []),
                ClaimSlotTimezoneLengthRule(maxLength: 16),
                ClaimSlotRequiredCodeRule(message: "claim slot needs a value"),
                ClaimSlotLabelLengthRule(maxLength: 80),
            ]
        )
    }
}
