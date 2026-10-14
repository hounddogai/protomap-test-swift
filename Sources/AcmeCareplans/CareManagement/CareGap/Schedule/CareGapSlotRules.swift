import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap slot must pass. Check returns its problems, or none.
    protocol CareGapSlotRule {
        func check(_ item: CareGapSlot) -> [String]
    }

    final class CareGapSlotCodeLengthRule: CareGapSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapSlotTitleLengthRule: CareGapSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapSlotRequiredCodeRule: CareGapSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapSlotRequiredNotesRule: CareGapSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapSlot) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a care gap slot.
    final class CareGapSlotValidator {
        var rules: [any CareGapSlotRule]

        init(rules: [any CareGapSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapSlot]) -> [String: [String]] {
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

    static func defaultCareGapSlotValidator() -> CareGapSlotValidator {
        return CareGapSlotValidator(
            rules: [
                CareGapSlotCodeLengthRule(maxLength: 32),
                CareGapSlotTitleLengthRule(maxLength: 86400),
                CareGapSlotRequiredCodeRule(message: "care gap slot needs this field"),
                CareGapSlotRequiredNotesRule(message: "care gap slot needs this field"),
            ]
        )
    }
}
