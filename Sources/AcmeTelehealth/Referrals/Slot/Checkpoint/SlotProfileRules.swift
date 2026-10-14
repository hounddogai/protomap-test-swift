import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot profile must pass. Check returns its problems, or none.
    protocol SlotProfileRule {
        func check(_ item: SlotProfile) -> [String]
    }

    final class SlotProfileCodeLengthRule: SlotProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotProfile) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotProfileCodePrefixRule: SlotProfileRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotProfile) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotProfileRequiredCodeRule: SlotProfileRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotProfile) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotProfilePinnedGuardRule: SlotProfileRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: SlotProfile) -> [String] {
            if item.pinned && (item.minimum > limit) {
                return ["minimum \(item.minimum) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class SlotProfileTitleLengthRule: SlotProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotProfile) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a slot profile.
    final class SlotProfileValidator {
        var rules: [any SlotProfileRule]

        init(rules: [any SlotProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SlotProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotProfile]) -> [String: [String]] {
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

    static func defaultSlotProfileValidator() -> SlotProfileValidator {
        return SlotProfileValidator(
            rules: [
                SlotProfileCodeLengthRule(maxLength: 86400),
                SlotProfileCodePrefixRule(prefix: "REF"),
                SlotProfileRequiredCodeRule(message: "slot profile needs this field"),
                SlotProfilePinnedGuardRule(limit: 8.6),
                SlotProfileTitleLengthRule(maxLength: 80),
            ]
        )
    }
}
