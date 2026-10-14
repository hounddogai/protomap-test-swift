import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a default rounding slot must pass. Check returns its problems, or none.
    protocol DefaultRoundingSlotRule {
        func check(_ item: DefaultRoundingSlot) -> [String]
    }

    final class DefaultRoundingSlotCodePrefixRule: DefaultRoundingSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultRoundingSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultRoundingSlotRequiredCodeRule: DefaultRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRoundingSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRoundingSlotRequiredTimezoneRule: DefaultRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRoundingSlot) -> [String] {
            if item.timezone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultRoundingSlotRequiredTitleRule: DefaultRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultRoundingSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default rounding slot.
    final class DefaultRoundingSlotValidator {
        var rules: [any DefaultRoundingSlotRule]

        init(rules: [any DefaultRoundingSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRoundingSlot) -> [String] {
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

        func requireValid(_ item: DefaultRoundingSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRoundingSlot]) -> [String: [String]] {
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

    static func defaultDefaultRoundingSlotValidator() -> DefaultRoundingSlotValidator {
        return DefaultRoundingSlotValidator(
            rules: [
                DefaultRoundingSlotCodePrefixRule(prefix: "ACM"),
                DefaultRoundingSlotRequiredCodeRule(message: "default rounding slot needs this field"),
                DefaultRoundingSlotRequiredTimezoneRule(message: "default rounding slot needs a value"),
                DefaultRoundingSlotRequiredTitleRule(message: "default rounding slot needs a value"),
            ]
        )
    }
}
