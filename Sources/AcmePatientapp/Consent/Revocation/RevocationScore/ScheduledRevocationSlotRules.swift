import AcmePlatform
import Foundation

extension Consent {
    /// A rule a scheduled revocation slot must pass. Check returns its problems, or none.
    protocol ScheduledRevocationSlotRule {
        func check(_ item: ScheduledRevocationSlot) -> [String]
    }

    final class ScheduledRevocationSlotRequiredRegionRule: ScheduledRevocationSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationSlot) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRevocationSlotRequiredCodeRule: ScheduledRevocationSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledRevocationSlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledRevocationSlotAllowedTitleRule: ScheduledRevocationSlotRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledRevocationSlot) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is not allowed"]
            }
            return []
        }
    }

    final class ScheduledRevocationSlotRevisionRangeRule: ScheduledRevocationSlotRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledRevocationSlot) -> [String] {
            let value = item.revision
            if value < min || value > max {
                return ["revision \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledRevocationSlotOwnerIDLengthRule: ScheduledRevocationSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledRevocationSlot) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledRevocationSlotArchivedGuardRule: ScheduledRevocationSlotRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ScheduledRevocationSlot) -> [String] {
            if item.archived && (item.revision > limit) {
                return ["revision \(item.revision) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled revocation slot.
    final class ScheduledRevocationSlotValidator {
        var rules: [any ScheduledRevocationSlotRule]

        init(rules: [any ScheduledRevocationSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledRevocationSlot) -> [String] {
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

        func requireValid(_ item: ScheduledRevocationSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledRevocationSlot]) -> [String: [String]] {
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

    static func defaultScheduledRevocationSlotValidator() -> ScheduledRevocationSlotValidator {
        return ScheduledRevocationSlotValidator(
            rules: [
                ScheduledRevocationSlotRequiredRegionRule(message: "scheduled revocation slot needs this field"),
                ScheduledRevocationSlotRequiredCodeRule(message: "scheduled revocation slot needs a value"),
                ScheduledRevocationSlotAllowedTitleRule(allowed: ["adaptive"]),
                ScheduledRevocationSlotRevisionRangeRule(min: 64, max: 120),
                ScheduledRevocationSlotOwnerIDLengthRule(maxLength: 32),
                ScheduledRevocationSlotArchivedGuardRule(limit: 1000),
            ]
        )
    }
}
