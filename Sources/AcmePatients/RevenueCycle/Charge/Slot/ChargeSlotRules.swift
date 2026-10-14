import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge slot must pass. Check returns its problems, or none.
    protocol ChargeSlotRule {
        func check(_ item: ChargeSlot) -> [String]
    }

    final class ChargeSlotLabelLengthRule: ChargeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeSlot) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ChargeSlotRequiredSpecialtyRule: ChargeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ChargeSlot) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ChargeSlotExternalRefLengthRule: ChargeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeSlot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge slot.
    final class ChargeSlotValidator {
        var rules: [any ChargeSlotRule]

        init(rules: [any ChargeSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeSlot) -> [String] {
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

        func requireValid(_ item: ChargeSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeSlot]) -> [String: [String]] {
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

    static func defaultChargeSlotValidator() -> ChargeSlotValidator {
        return ChargeSlotValidator(
            rules: [
                ChargeSlotLabelLengthRule(maxLength: 32),
                ChargeSlotRequiredSpecialtyRule(message: "charge slot needs an entry"),
                ChargeSlotExternalRefLengthRule(maxLength: 3600),
            ]
        )
    }
}
