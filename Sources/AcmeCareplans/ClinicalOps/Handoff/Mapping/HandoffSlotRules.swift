import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff slot must pass. Check returns its problems, or none.
    protocol HandoffSlotRule {
        func check(_ item: HandoffSlot) -> [String]
    }

    final class HandoffSlotChecksumLengthRule: HandoffSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffSlot) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffSlotPinnedGuardRule: HandoffSlotRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: HandoffSlot) -> [String] {
            if item.pinned && (item.floorValue > limit) {
                return ["floor value \(item.floorValue) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class HandoffSlotRequiredPhoneRule: HandoffSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffSlot) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a handoff slot.
    final class HandoffSlotValidator {
        var rules: [any HandoffSlotRule]

        init(rules: [any HandoffSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffSlot) -> [String] {
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

        func requireValid(_ item: HandoffSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffSlot]) -> [String: [String]] {
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

    static func defaultHandoffSlotValidator() -> HandoffSlotValidator {
        return HandoffSlotValidator(
            rules: [
                HandoffSlotChecksumLengthRule(maxLength: 32),
                HandoffSlotPinnedGuardRule(limit: 3.6),
                HandoffSlotRequiredPhoneRule(message: "handoff slot needs this field"),
            ]
        )
    }
}
