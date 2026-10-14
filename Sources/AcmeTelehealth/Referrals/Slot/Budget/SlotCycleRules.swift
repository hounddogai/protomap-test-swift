import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot cycle must pass. Check returns its problems, or none.
    protocol SlotCycleRule {
        func check(_ item: SlotCycle) -> [String]
    }

    final class SlotCycleCodeLengthRule: SlotCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotCycle) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotCycleArchivedGuardRule: SlotCycleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SlotCycle) -> [String] {
            if item.archived && (item.ceiling > limit) {
                return ["ceiling \(item.ceiling) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class SlotCycleRequiredCodeRule: SlotCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot cycle.
    final class SlotCycleValidator {
        var rules: [any SlotCycleRule]

        init(rules: [any SlotCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotCycle) -> [String] {
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

        func requireValid(_ item: SlotCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotCycle]) -> [String: [String]] {
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

    static func defaultSlotCycleValidator() -> SlotCycleValidator {
        return SlotCycleValidator(
            rules: [
                SlotCycleCodeLengthRule(maxLength: 1000),
                SlotCycleArchivedGuardRule(limit: 4.2),
                SlotCycleRequiredCodeRule(message: "slot cycle needs this field"),
            ]
        )
    }
}
