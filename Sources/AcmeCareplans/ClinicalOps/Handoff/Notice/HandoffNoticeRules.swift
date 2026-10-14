import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a handoff notice must pass. Check returns its problems, or none.
    protocol HandoffNoticeRule {
        func check(_ item: HandoffNotice) -> [String]
    }

    final class HandoffNoticeQuantityRangeRule: HandoffNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffNotice) -> [String] {
            let value = item.quantity
            if value < min || value > max {
                return ["quantity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class HandoffNoticeRequiredLocaleRule: HandoffNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffNotice) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffNoticeCodeLengthRule: HandoffNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffNoticeLocaleLengthRule: HandoffNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: HandoffNotice) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class HandoffNoticeRequiredTitleRule: HandoffNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: HandoffNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class HandoffNoticeRetriesRangeRule: HandoffNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: HandoffNotice) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a handoff notice.
    final class HandoffNoticeValidator {
        var rules: [any HandoffNoticeRule]

        init(rules: [any HandoffNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: HandoffNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: HandoffNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [HandoffNotice]) -> [String: [String]] {
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

    static func defaultHandoffNoticeValidator() -> HandoffNoticeValidator {
        return HandoffNoticeValidator(
            rules: [
                HandoffNoticeQuantityRangeRule(min: 120, max: 1000),
                HandoffNoticeRequiredLocaleRule(message: "handoff notice needs a value"),
                HandoffNoticeCodeLengthRule(maxLength: 255),
                HandoffNoticeLocaleLengthRule(maxLength: 3600),
                HandoffNoticeRequiredTitleRule(message: "handoff notice needs this field"),
                HandoffNoticeRetriesRangeRule(min: 3600, max: 86400),
            ]
        )
    }
}
