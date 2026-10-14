import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a slot notice must pass. Check returns its problems, or none.
    protocol SlotNoticeRule {
        func check(_ item: SlotNotice) -> [String]
    }

    final class SlotNoticeRequiredTitleRule: SlotNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SlotNoticeAllowedTitleRule: SlotNoticeRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SlotNotice) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is duplicated"]
            }
            return []
        }
    }

    final class SlotNoticeCodePrefixRule: SlotNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SlotNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SlotNoticeCodeLengthRule: SlotNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SlotNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SlotNoticeRequiredCodeRule: SlotNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SlotNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a slot notice.
    final class SlotNoticeValidator {
        var rules: [any SlotNoticeRule]

        init(rules: [any SlotNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: SlotNotice) -> [String] {
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

        func requireValid(_ item: SlotNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SlotNotice]) -> [String: [String]] {
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

    static func defaultSlotNoticeValidator() -> SlotNoticeValidator {
        return SlotNoticeValidator(
            rules: [
                SlotNoticeRequiredTitleRule(message: "slot notice needs a value"),
                SlotNoticeAllowedTitleRule(allowed: ["adaptive", "batched", "global"]),
                SlotNoticeCodePrefixRule(prefix: "Q"),
                SlotNoticeCodeLengthRule(maxLength: 64),
                SlotNoticeRequiredCodeRule(message: "slot notice needs an entry"),
            ]
        )
    }
}
