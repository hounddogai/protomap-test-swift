import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime slot must pass. Check returns its problems, or none.
    protocol OvertimeSlotRule {
        func check(_ item: OvertimeSlot) -> [String]
    }

    final class OvertimeSlotRequiredNameRule: OvertimeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeSlot) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeSlotRequiredSummaryRule: OvertimeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeSlot) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeSlotNameLengthRule: OvertimeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeSlot) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeSlotRequiredBedRule: OvertimeSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeSlot) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeSlotSummaryLengthRule: OvertimeSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeSlot) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a overtime slot.
    final class OvertimeSlotValidator {
        var rules: [any OvertimeSlotRule]

        init(rules: [any OvertimeSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeSlot) -> [String] {
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

        func requireValid(_ item: OvertimeSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeSlot]) -> [String: [String]] {
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

    static func defaultOvertimeSlotValidator() -> OvertimeSlotValidator {
        return OvertimeSlotValidator(
            rules: [
                OvertimeSlotRequiredNameRule(message: "overtime slot needs this field"),
                OvertimeSlotRequiredSummaryRule(message: "overtime slot needs an entry"),
                OvertimeSlotNameLengthRule(maxLength: 80),
                OvertimeSlotRequiredBedRule(message: "overtime slot needs an entry"),
                OvertimeSlotSummaryLengthRule(maxLength: 3600),
            ]
        )
    }
}
