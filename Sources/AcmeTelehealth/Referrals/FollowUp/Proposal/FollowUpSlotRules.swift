import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up slot must pass. Check returns its problems, or none.
    protocol FollowUpSlotRule {
        func check(_ item: FollowUpSlot) -> [String]
    }

    final class FollowUpSlotTitleLengthRule: FollowUpSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpSlot) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpSlotCodePrefixRule: FollowUpSlotRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpSlot) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpSlotCodeLengthRule: FollowUpSlotRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: FollowUpSlot) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class FollowUpSlotRequiredTitleRule: FollowUpSlotRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpSlot) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up slot.
    final class FollowUpSlotValidator {
        var rules: [any FollowUpSlotRule]

        init(rules: [any FollowUpSlotRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpSlot) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpSlot) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpSlot]) -> [String: [String]] {
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

    static func defaultFollowUpSlotValidator() -> FollowUpSlotValidator {
        return FollowUpSlotValidator(
            rules: [
                FollowUpSlotTitleLengthRule(maxLength: 1000),
                FollowUpSlotCodePrefixRule(prefix: "REF"),
                FollowUpSlotCodeLengthRule(maxLength: 64),
                FollowUpSlotRequiredTitleRule(message: "follow up slot needs this field"),
            ]
        )
    }
}
