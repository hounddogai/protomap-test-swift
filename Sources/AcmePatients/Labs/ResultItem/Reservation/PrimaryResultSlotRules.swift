import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary result slot must pass. Check returns its problems, or none.
    protocol PrimaryResultSlotRule {
        func check(_ item: PrimaryResultSlot) -> [String]
    }

    final class PrimaryResultSlotAllowedPhoneRule: PrimaryResultSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: PrimaryResultSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.phone)) {
                return ["phone \(item.phone) is above maximum"]
            }
            return []
        }
    }

    final class PrimaryResultSlotRequiredPhoneRule: PrimaryResultSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryResultSlot) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryResultSlotNameLengthRule: PrimaryResultSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryResultSlotPhoneLengthRule: PrimaryResultSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultSlot) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryResultSlotRequiredCodeRule: PrimaryResultSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryResultSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryResultSlotCodeLengthRule: PrimaryResultSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryResultSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary result slot.
    final class PrimaryResultSlotValidator {
        var rules: [any PrimaryResultSlotRule]

        init(rules: [any PrimaryResultSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryResultSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryResultSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryResultSlot]) -> [String: [String]] {
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

    static func defaultPrimaryResultSlotValidator() -> PrimaryResultSlotValidator {
        return PrimaryResultSlotValidator(
            rules: [
                PrimaryResultSlotAllowedPhoneRule(allowed: []),
                PrimaryResultSlotRequiredPhoneRule(message: "primary result slot needs an entry"),
                PrimaryResultSlotNameLengthRule(maxLength: 1000),
                PrimaryResultSlotPhoneLengthRule(maxLength: 32),
                PrimaryResultSlotRequiredCodeRule(message: "primary result slot needs a value"),
                PrimaryResultSlotCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
