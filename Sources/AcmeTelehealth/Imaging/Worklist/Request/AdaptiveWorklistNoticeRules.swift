import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a adaptive worklist notice must pass. Check returns its problems, or none.
    protocol AdaptiveWorklistNoticeRule {
        func check(_ item: AdaptiveWorklistNotice) -> [String]
    }

    final class AdaptiveWorklistNoticeRequiredBedRule: AdaptiveWorklistNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveWorklistNotice) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveWorklistNoticeTitleLengthRule: AdaptiveWorklistNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveWorklistNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveWorklistNoticeCodePrefixRule: AdaptiveWorklistNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: AdaptiveWorklistNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive worklist notice.
    final class AdaptiveWorklistNoticeValidator {
        var rules: [any AdaptiveWorklistNoticeRule]

        init(rules: [any AdaptiveWorklistNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveWorklistNotice) -> [String] {
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

        func requireValid(_ item: AdaptiveWorklistNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveWorklistNotice]) -> [String: [String]] {
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

    static func defaultAdaptiveWorklistNoticeValidator() -> AdaptiveWorklistNoticeValidator {
        return AdaptiveWorklistNoticeValidator(
            rules: [
                AdaptiveWorklistNoticeRequiredBedRule(message: "adaptive worklist notice needs a value"),
                AdaptiveWorklistNoticeTitleLengthRule(maxLength: 16),
                AdaptiveWorklistNoticeCodePrefixRule(prefix: "Q"),
            ]
        )
    }
}
