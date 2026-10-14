import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a capped eligibility slot must pass. Check returns its problems, or none.
    protocol CappedEligibilitySlotRule {
        func check(_ item: CappedEligibilitySlot) -> [String]
    }

    final class CappedEligibilitySlotRequiredOwnerIDRule: CappedEligibilitySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedEligibilitySlot) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedEligibilitySlotCopayRangeRule: CappedEligibilitySlotRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedEligibilitySlot) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CappedEligibilitySlotAllowedContactEmailRule: CappedEligibilitySlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedEligibilitySlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is stale"]
            }
            return []
        }
    }

    final class CappedEligibilitySlotCodePrefixRule: CappedEligibilitySlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedEligibilitySlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CappedEligibilitySlotTitleLengthRule: CappedEligibilitySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedEligibilitySlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped eligibility slot.
    final class CappedEligibilitySlotValidator {
        var rules: [any CappedEligibilitySlotRule]

        init(rules: [any CappedEligibilitySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedEligibilitySlot) -> [String] {
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

        func requireValid(_ item: CappedEligibilitySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedEligibilitySlot]) -> [String: [String]] {
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

    static func defaultCappedEligibilitySlotValidator() -> CappedEligibilitySlotValidator {
        return CappedEligibilitySlotValidator(
            rules: [
                CappedEligibilitySlotRequiredOwnerIDRule(message: "capped eligibility slot needs a value"),
                CappedEligibilitySlotCopayRangeRule(min: 3.8, max: 4793.2),
                CappedEligibilitySlotAllowedContactEmailRule(allowed: []),
                CappedEligibilitySlotCodePrefixRule(prefix: "ACM"),
                CappedEligibilitySlotTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
