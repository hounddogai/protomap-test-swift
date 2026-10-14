import AcmePlatform
import Foundation

extension Consent {
    /// A rule a consent form notice must pass. Check returns its problems, or none.
    protocol ConsentFormNoticeRule {
        func check(_ item: ConsentFormNotice) -> [String]
    }

    final class ConsentFormNoticeCodeLengthRule: ConsentFormNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ConsentFormNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ConsentFormNoticeCodePrefixRule: ConsentFormNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ConsentFormNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ConsentFormNoticeRequiredCodeRule: ConsentFormNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ConsentFormNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a consent form notice.
    final class ConsentFormNoticeValidator {
        var rules: [any ConsentFormNoticeRule]

        init(rules: [any ConsentFormNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: ConsentFormNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ConsentFormNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ConsentFormNotice]) -> [String: [String]] {
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

    static func defaultConsentFormNoticeValidator() -> ConsentFormNoticeValidator {
        return ConsentFormNoticeValidator(
            rules: [
                ConsentFormNoticeCodeLengthRule(maxLength: 120),
                ConsentFormNoticeCodePrefixRule(prefix: "OPS"),
                ConsentFormNoticeRequiredCodeRule(message: "consent form notice needs a value"),
            ]
        )
    }
}
