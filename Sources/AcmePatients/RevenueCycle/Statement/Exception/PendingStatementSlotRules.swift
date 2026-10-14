import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a pending statement slot must pass. Check returns its problems, or none.
    protocol PendingStatementSlotRule {
        func check(_ item: PendingStatementSlot) -> [String]
    }

    final class PendingStatementSlotSequenceRangeRule: PendingStatementSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingStatementSlot) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PendingStatementSlotCodeLengthRule: PendingStatementSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PendingStatementSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PendingStatementSlotRequiredTitleRule: PendingStatementSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PendingStatementSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PendingStatementSlotVisitMinutesRangeRule: PendingStatementSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PendingStatementSlot) -> [String] {
            let value = item.visitMinutes
            var problems: [String] = []
            if value < min {
                problems.append("visit minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("visit minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a pending statement slot.
    final class PendingStatementSlotValidator {
        var rules: [any PendingStatementSlotRule]

        init(rules: [any PendingStatementSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: PendingStatementSlot) -> [String] {
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

        func requireValid(_ item: PendingStatementSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PendingStatementSlot]) -> [String: [String]] {
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

    static func defaultPendingStatementSlotValidator() -> PendingStatementSlotValidator {
        return PendingStatementSlotValidator(
            rules: [
                PendingStatementSlotSequenceRangeRule(min: 32, max: 3600),
                PendingStatementSlotCodeLengthRule(maxLength: 255),
                PendingStatementSlotRequiredTitleRule(message: "pending statement slot needs this field"),
                PendingStatementSlotVisitMinutesRangeRule(min: 120, max: 3600),
            ]
        )
    }
}
