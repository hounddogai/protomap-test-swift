import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a lenient outreach slot must pass. Check returns its problems, or none.
    protocol LenientOutreachSlotRule {
        func check(_ item: LenientOutreachSlot) -> [String]
    }

    final class LenientOutreachSlotRequiredTitleRule: LenientOutreachSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOutreachSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOutreachSlotRequiredCodeRule: LenientOutreachSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientOutreachSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientOutreachSlotCodeLengthRule: LenientOutreachSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientOutreachSlotTitleLengthRule: LenientOutreachSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientOutreachSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient outreach slot.
    final class LenientOutreachSlotValidator {
        var rules: [any LenientOutreachSlotRule]

        init(rules: [any LenientOutreachSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientOutreachSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientOutreachSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientOutreachSlot]) -> [String: [String]] {
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

    static func defaultLenientOutreachSlotValidator() -> LenientOutreachSlotValidator {
        return LenientOutreachSlotValidator(
            rules: [
                LenientOutreachSlotRequiredTitleRule(message: "lenient outreach slot needs an entry"),
                LenientOutreachSlotRequiredCodeRule(message: "lenient outreach slot needs this field"),
                LenientOutreachSlotCodeLengthRule(maxLength: 120),
                LenientOutreachSlotTitleLengthRule(maxLength: 32),
            ]
        )
    }
}
