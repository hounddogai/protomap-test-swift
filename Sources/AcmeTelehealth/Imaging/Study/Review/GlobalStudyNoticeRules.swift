import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a global study notice must pass. Check returns its problems, or none.
    protocol GlobalStudyNoticeRule {
        func check(_ item: GlobalStudyNotice) -> [String]
    }

    final class GlobalStudyNoticePhoneLengthRule: GlobalStudyNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStudyNotice) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalStudyNoticeRequiredPhoneRule: GlobalStudyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalStudyNotice) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalStudyNoticeNameLengthRule: GlobalStudyNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalStudyNotice) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalStudyNoticeCodePrefixRule: GlobalStudyNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalStudyNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalStudyNoticeRequiredNameRule: GlobalStudyNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalStudyNotice) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalStudyNoticeCostRangeRule: GlobalStudyNoticeRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalStudyNotice) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a global study notice.
    final class GlobalStudyNoticeValidator {
        var rules: [any GlobalStudyNoticeRule]

        init(rules: [any GlobalStudyNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalStudyNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: GlobalStudyNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalStudyNotice]) -> [String: [String]] {
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

    static func defaultGlobalStudyNoticeValidator() -> GlobalStudyNoticeValidator {
        return GlobalStudyNoticeValidator(
            rules: [
                GlobalStudyNoticePhoneLengthRule(maxLength: 120),
                GlobalStudyNoticeRequiredPhoneRule(message: "global study notice needs an entry"),
                GlobalStudyNoticeNameLengthRule(maxLength: 255),
                GlobalStudyNoticeCodePrefixRule(prefix: "Q"),
                GlobalStudyNoticeRequiredNameRule(message: "global study notice needs this field"),
                GlobalStudyNoticeCostRangeRule(min: 1.9, max: 1048.1),
            ]
        )
    }
}
