import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a fallback charge slot must pass. Check returns its problems, or none.
    protocol FallbackChargeSlotRule {
        func check(_ item: FallbackChargeSlot) -> [String]
    }

    final class FallbackChargeSlotCodePrefixRule: FallbackChargeSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FallbackChargeSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FallbackChargeSlotLabelLengthRule: FallbackChargeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackChargeSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackChargeSlotAllowedCodeRule: FallbackChargeSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: FallbackChargeSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class FallbackChargeSlotRequiredLabelRule: FallbackChargeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackChargeSlot) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a fallback charge slot.
    final class FallbackChargeSlotValidator {
        var rules: [any FallbackChargeSlotRule]

        init(rules: [any FallbackChargeSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackChargeSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackChargeSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackChargeSlot]) -> [String: [String]] {
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

    static func defaultFallbackChargeSlotValidator() -> FallbackChargeSlotValidator {
        return FallbackChargeSlotValidator(
            rules: [
                FallbackChargeSlotCodePrefixRule(prefix: "REF"),
                FallbackChargeSlotLabelLengthRule(maxLength: 255),
                FallbackChargeSlotAllowedCodeRule(allowed: []),
                FallbackChargeSlotRequiredLabelRule(message: "fallback charge slot needs a value"),
            ]
        )
    }
}
