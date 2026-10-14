import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a legacy recall slot must pass. Check returns its problems, or none.
    protocol LegacyRecallSlotRule {
        func check(_ item: LegacyRecallSlot) -> [String]
    }

    final class LegacyRecallSlotSegmentLengthRule: LegacyRecallSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallSlot) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRecallSlotCodeLengthRule: LegacyRecallSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRecallSlotSpecialtyLengthRule: LegacyRecallSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyRecallSlot) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyRecallSlotRequiredSpecialtyRule: LegacyRecallSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyRecallSlot) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy recall slot.
    final class LegacyRecallSlotValidator {
        var rules: [any LegacyRecallSlotRule]

        init(rules: [any LegacyRecallSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyRecallSlot) -> [String] {
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

        func requireValid(_ item: LegacyRecallSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyRecallSlot]) -> [String: [String]] {
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

    static func defaultLegacyRecallSlotValidator() -> LegacyRecallSlotValidator {
        return LegacyRecallSlotValidator(
            rules: [
                LegacyRecallSlotSegmentLengthRule(maxLength: 255),
                LegacyRecallSlotCodeLengthRule(maxLength: 255),
                LegacyRecallSlotSpecialtyLengthRule(maxLength: 64),
                LegacyRecallSlotRequiredSpecialtyRule(message: "legacy recall slot needs a value"),
            ]
        )
    }
}
