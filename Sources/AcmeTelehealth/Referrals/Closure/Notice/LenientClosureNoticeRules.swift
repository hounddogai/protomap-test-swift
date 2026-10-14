import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a lenient closure notice must pass. Check returns its problems, or none.
    protocol LenientClosureNoticeRule {
        func check(_ item: LenientClosureNotice) -> [String]
    }

    final class LenientClosureNoticeRequiredTitleRule: LenientClosureNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClosureNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientClosureNoticeCodeLengthRule: LenientClosureNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LenientClosureNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LenientClosureNoticeRequiredCodeRule: LenientClosureNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientClosureNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientClosureNoticeCodePrefixRule: LenientClosureNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: LenientClosureNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a lenient closure notice.
    final class LenientClosureNoticeValidator {
        var rules: [any LenientClosureNoticeRule]

        init(rules: [any LenientClosureNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientClosureNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientClosureNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientClosureNotice]) -> [String: [String]] {
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

    static func defaultLenientClosureNoticeValidator() -> LenientClosureNoticeValidator {
        return LenientClosureNoticeValidator(
            rules: [
                LenientClosureNoticeRequiredTitleRule(message: "lenient closure notice needs a value"),
                LenientClosureNoticeCodeLengthRule(maxLength: 120),
                LenientClosureNoticeRequiredCodeRule(message: "lenient closure notice needs a value"),
                LenientClosureNoticeCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
