import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a default float pool notice must pass. Check returns its problems, or none.
    protocol DefaultFloatPoolNoticeRule {
        func check(_ item: DefaultFloatPoolNotice) -> [String]
    }

    final class DefaultFloatPoolNoticeLabelLengthRule: DefaultFloatPoolNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolNotice) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolNoticeRequiredCodeRule: DefaultFloatPoolNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFloatPoolNoticeCodeLengthRule: DefaultFloatPoolNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultFloatPoolNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultFloatPoolNoticeRequiredLabelRule: DefaultFloatPoolNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultFloatPoolNoticeRequiredSummaryRule: DefaultFloatPoolNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultFloatPoolNotice) -> [String] {
            if item.summary.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default float pool notice.
    final class DefaultFloatPoolNoticeValidator {
        var rules: [any DefaultFloatPoolNoticeRule]

        init(rules: [any DefaultFloatPoolNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultFloatPoolNotice) -> [String] {
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

        func requireValid(_ item: DefaultFloatPoolNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultFloatPoolNotice]) -> [String: [String]] {
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

    static func defaultDefaultFloatPoolNoticeValidator() -> DefaultFloatPoolNoticeValidator {
        return DefaultFloatPoolNoticeValidator(
            rules: [
                DefaultFloatPoolNoticeLabelLengthRule(maxLength: 86400),
                DefaultFloatPoolNoticeRequiredCodeRule(message: "default float pool notice needs an entry"),
                DefaultFloatPoolNoticeCodeLengthRule(maxLength: 3600),
                DefaultFloatPoolNoticeRequiredLabelRule(message: "default float pool notice needs a value"),
                DefaultFloatPoolNoticeRequiredSummaryRule(message: "default float pool notice needs a value"),
            ]
        )
    }
}
