import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a formulary slot must pass. Check returns its problems, or none.
    protocol FormularySlotRule {
        func check(_ item: FormularySlot) -> [String]
    }

    final class FormularySlotExternalRefLengthRule: FormularySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularySlot) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularySlotCodePrefixRule: FormularySlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FormularySlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FormularySlotStartsAtRangeRule: FormularySlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FormularySlot) -> [String] {
            let value = item.startsAt
            var problems: [String] = []
            if value < min {
                problems.append("starts at \(value) is below \(min)")
            }
            if value > max {
                problems.append("starts at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class FormularySlotTitleLengthRule: FormularySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularySlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FormularySlotRequiredPhoneRule: FormularySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FormularySlot) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FormularySlotPhoneLengthRule: FormularySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FormularySlot) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a formulary slot.
    final class FormularySlotValidator {
        var rules: [any FormularySlotRule]

        init(rules: [any FormularySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: FormularySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FormularySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FormularySlot]) -> [String: [String]] {
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

    static func defaultFormularySlotValidator() -> FormularySlotValidator {
        return FormularySlotValidator(
            rules: [
                FormularySlotExternalRefLengthRule(maxLength: 1000),
                FormularySlotCodePrefixRule(prefix: "ACM"),
                FormularySlotStartsAtRangeRule(min: 1000, max: 86400),
                FormularySlotTitleLengthRule(maxLength: 64),
                FormularySlotRequiredPhoneRule(message: "formulary slot needs an entry"),
                FormularySlotPhoneLengthRule(maxLength: 3600),
            ]
        )
    }
}
