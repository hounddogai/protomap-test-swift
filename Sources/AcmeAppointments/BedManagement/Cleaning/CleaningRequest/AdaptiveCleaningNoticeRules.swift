import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a adaptive cleaning notice must pass. Check returns its problems, or none.
    protocol AdaptiveCleaningNoticeRule {
        func check(_ item: AdaptiveCleaningNotice) -> [String]
    }

    final class AdaptiveCleaningNoticeBedLengthRule: AdaptiveCleaningNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveCleaningNotice) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveCleaningNoticeRequiredTitleRule: AdaptiveCleaningNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveCleaningNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveCleaningNoticeGraceDaysRangeRule: AdaptiveCleaningNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveCleaningNotice) -> [String] {
            let value = item.graceDays
            if value < min || value > max {
                return ["grace days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive cleaning notice.
    final class AdaptiveCleaningNoticeValidator {
        var rules: [any AdaptiveCleaningNoticeRule]

        init(rules: [any AdaptiveCleaningNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveCleaningNotice) -> [String] {
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

        func requireValid(_ item: AdaptiveCleaningNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveCleaningNotice]) -> [String: [String]] {
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

    static func defaultAdaptiveCleaningNoticeValidator() -> AdaptiveCleaningNoticeValidator {
        return AdaptiveCleaningNoticeValidator(
            rules: [
                AdaptiveCleaningNoticeBedLengthRule(maxLength: 255),
                AdaptiveCleaningNoticeRequiredTitleRule(message: "adaptive cleaning notice needs an entry"),
                AdaptiveCleaningNoticeGraceDaysRangeRule(min: 32, max: 255),
            ]
        )
    }
}
