import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a adaptive follow up notice must pass. Check returns its problems, or none.
    protocol AdaptiveFollowUpNoticeRule {
        func check(_ item: AdaptiveFollowUpNotice) -> [String]
    }

    final class AdaptiveFollowUpNoticePriorityRangeRule: AdaptiveFollowUpNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFollowUpNotice) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveFollowUpNoticeTimezoneLengthRule: AdaptiveFollowUpNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveFollowUpNotice) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AdaptiveFollowUpNoticeWindowDaysRangeRule: AdaptiveFollowUpNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveFollowUpNotice) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive follow up notice.
    final class AdaptiveFollowUpNoticeValidator {
        var rules: [any AdaptiveFollowUpNoticeRule]

        init(rules: [any AdaptiveFollowUpNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveFollowUpNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AdaptiveFollowUpNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveFollowUpNotice]) -> [String: [String]] {
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

    static func defaultAdaptiveFollowUpNoticeValidator() -> AdaptiveFollowUpNoticeValidator {
        return AdaptiveFollowUpNoticeValidator(
            rules: [
                AdaptiveFollowUpNoticePriorityRangeRule(min: 64, max: 120),
                AdaptiveFollowUpNoticeTimezoneLengthRule(maxLength: 64),
                AdaptiveFollowUpNoticeWindowDaysRangeRule(min: 16, max: 16),
            ]
        )
    }
}
