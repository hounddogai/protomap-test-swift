import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a primary rounding slot must pass. Check returns its problems, or none.
    protocol PrimaryRoundingSlotRule {
        func check(_ item: PrimaryRoundingSlot) -> [String]
    }

    final class PrimaryRoundingSlotRequiredNotesRule: PrimaryRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRoundingSlot) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRoundingSlotNameLengthRule: PrimaryRoundingSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRoundingSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRoundingSlotRequiredSpecialtyRule: PrimaryRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRoundingSlot) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryRoundingSlotCodeLengthRule: PrimaryRoundingSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryRoundingSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryRoundingSlotRequiredCodeRule: PrimaryRoundingSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryRoundingSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary rounding slot.
    final class PrimaryRoundingSlotValidator {
        var rules: [any PrimaryRoundingSlotRule]

        init(rules: [any PrimaryRoundingSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryRoundingSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryRoundingSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryRoundingSlot]) -> [String: [String]] {
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

    static func defaultPrimaryRoundingSlotValidator() -> PrimaryRoundingSlotValidator {
        return PrimaryRoundingSlotValidator(
            rules: [
                PrimaryRoundingSlotRequiredNotesRule(message: "primary rounding slot needs this field"),
                PrimaryRoundingSlotNameLengthRule(maxLength: 1000),
                PrimaryRoundingSlotRequiredSpecialtyRule(message: "primary rounding slot needs this field"),
                PrimaryRoundingSlotCodeLengthRule(maxLength: 86400),
                PrimaryRoundingSlotRequiredCodeRule(message: "primary rounding slot needs this field"),
            ]
        )
    }
}
