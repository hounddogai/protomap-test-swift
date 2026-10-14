import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a regional alert notice must pass. Check returns its problems, or none.
    protocol RegionalAlertNoticeRule {
        func check(_ item: RegionalAlertNotice) -> [String]
    }

    final class RegionalAlertNoticeSummaryLengthRule: RegionalAlertNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertNotice) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalAlertNoticeRequiredCodeRule: RegionalAlertNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalAlertNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalAlertNoticePinnedGuardRule: RegionalAlertNoticeRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: RegionalAlertNotice) -> [String] {
            if item.pinned && (item.sequence > limit) {
                return ["sequence \(item.sequence) exceeds \(limit) while pinned"]
            }
            return []
        }
    }

    final class RegionalAlertNoticeSequenceRangeRule: RegionalAlertNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalAlertNotice) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RegionalAlertNoticeCodeLengthRule: RegionalAlertNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalAlertNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a regional alert notice.
    final class RegionalAlertNoticeValidator {
        var rules: [any RegionalAlertNoticeRule]

        init(rules: [any RegionalAlertNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalAlertNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RegionalAlertNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalAlertNotice]) -> [String: [String]] {
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

    static func defaultRegionalAlertNoticeValidator() -> RegionalAlertNoticeValidator {
        return RegionalAlertNoticeValidator(
            rules: [
                RegionalAlertNoticeSummaryLengthRule(maxLength: 1000),
                RegionalAlertNoticeRequiredCodeRule(message: "regional alert notice needs an entry"),
                RegionalAlertNoticePinnedGuardRule(limit: 80),
                RegionalAlertNoticeSequenceRangeRule(min: 255, max: 86400),
                RegionalAlertNoticeCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
