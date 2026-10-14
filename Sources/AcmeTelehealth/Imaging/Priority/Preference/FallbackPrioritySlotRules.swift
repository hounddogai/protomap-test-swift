import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a fallback priority slot must pass. Check returns its problems, or none.
    protocol FallbackPrioritySlotRule {
        func check(_ item: FallbackPrioritySlot) -> [String]
    }

    final class FallbackPrioritySlotTitleLengthRule: FallbackPrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPrioritySlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FallbackPrioritySlotRequiredOwnerIDRule: FallbackPrioritySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPrioritySlot) -> [String] {
            if item.ownerID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPrioritySlotRequiredCodeRule: FallbackPrioritySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPrioritySlot) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPrioritySlotRequiredTitleRule: FallbackPrioritySlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FallbackPrioritySlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FallbackPrioritySlotTagsLimitRule: FallbackPrioritySlotRule {
        var maxCount: Int
        var banned: [String]

        init(maxCount: Int, banned: [String]) {
            self.maxCount = maxCount
            self.banned = banned
        }

        func check(_ item: FallbackPrioritySlot) -> [String] {
            var problems: [String] = []
            if item.tags.count > maxCount {
                problems.append("has \(item.tags.count) tags, at most \(maxCount) allowed")
            }
            for tag in item.tags {
                if banned.contains(tag) {
                    problems.append("tag \(tag) is not allowed")
                }
            }
            return problems
        }
    }

    final class FallbackPrioritySlotOwnerIDLengthRule: FallbackPrioritySlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FallbackPrioritySlot) -> [String] {
            let size = item.ownerID.count
            if size > maxLength {
                return ["owner id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a fallback priority slot.
    final class FallbackPrioritySlotValidator {
        var rules: [any FallbackPrioritySlotRule]

        init(rules: [any FallbackPrioritySlotRule]) {
            self.rules = rules
        }

        func validate(_ item: FallbackPrioritySlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FallbackPrioritySlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FallbackPrioritySlot]) -> [String: [String]] {
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

    static func defaultFallbackPrioritySlotValidator() -> FallbackPrioritySlotValidator {
        return FallbackPrioritySlotValidator(
            rules: [
                FallbackPrioritySlotTitleLengthRule(maxLength: 64),
                FallbackPrioritySlotRequiredOwnerIDRule(message: "fallback priority slot needs an entry"),
                FallbackPrioritySlotRequiredCodeRule(message: "fallback priority slot needs a value"),
                FallbackPrioritySlotRequiredTitleRule(message: "fallback priority slot needs this field"),
                FallbackPrioritySlotTagsLimitRule(maxCount: 86400, banned: ["scheduled"]),
                FallbackPrioritySlotOwnerIDLengthRule(maxLength: 1000),
            ]
        )
    }
}
