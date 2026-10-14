import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall notice must pass. Check returns its problems, or none.
    protocol RecallNoticeRule {
        func check(_ item: RecallNotice) -> [String]
    }

    final class RecallNoticeRequiredCodeRule: RecallNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallNoticeRequiredTitleRule: RecallNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallNoticeTitleLengthRule: RecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallNoticeCodeLengthRule: RecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallNoticeProcedureCodeLengthRule: RecallNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallNotice) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallNoticeRequiredChannelRule: RecallNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallNotice) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall notice.
    final class RecallNoticeValidator {
        var rules: [any RecallNoticeRule]

        init(rules: [any RecallNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallNotice) -> [String] {
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

        func requireValid(_ item: RecallNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallNotice]) -> [String: [String]] {
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

    static func defaultRecallNoticeValidator() -> RecallNoticeValidator {
        return RecallNoticeValidator(
            rules: [
                RecallNoticeRequiredCodeRule(message: "recall notice needs this field"),
                RecallNoticeRequiredTitleRule(message: "recall notice needs a value"),
                RecallNoticeTitleLengthRule(maxLength: 86400),
                RecallNoticeCodeLengthRule(maxLength: 80),
                RecallNoticeProcedureCodeLengthRule(maxLength: 16),
                RecallNoticeRequiredChannelRule(message: "recall notice needs an entry"),
            ]
        )
    }
}
