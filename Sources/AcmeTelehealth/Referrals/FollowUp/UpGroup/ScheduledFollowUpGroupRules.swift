import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled follow up group must pass. Check returns its problems, or none.
    protocol ScheduledFollowUpGroupRule {
        func check(_ item: ScheduledFollowUpGroup) -> [String]
    }

    final class ScheduledFollowUpGroupCodeLengthRule: ScheduledFollowUpGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpGroupRequiredCodeRule: ScheduledFollowUpGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFollowUpGroupRequiredSegmentRule: ScheduledFollowUpGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpGroup) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledFollowUpGroupEndsAtRangeRule: ScheduledFollowUpGroupRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFollowUpGroup) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledFollowUpGroupRatioRangeRule: ScheduledFollowUpGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFollowUpGroup) -> [String] {
            let value = item.ratio
            var problems: [String] = []
            if value < min {
                problems.append("ratio \(value) is below \(min)")
            }
            if value > max {
                problems.append("ratio \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledFollowUpGroupRequiredNameRule: ScheduledFollowUpGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledFollowUpGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled follow up group.
    final class ScheduledFollowUpGroupValidator {
        var rules: [any ScheduledFollowUpGroupRule]

        init(rules: [any ScheduledFollowUpGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFollowUpGroup) -> [String] {
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

        func requireValid(_ item: ScheduledFollowUpGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFollowUpGroup]) -> [String: [String]] {
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

    static func defaultScheduledFollowUpGroupValidator() -> ScheduledFollowUpGroupValidator {
        return ScheduledFollowUpGroupValidator(
            rules: [
                ScheduledFollowUpGroupCodeLengthRule(maxLength: 255),
                ScheduledFollowUpGroupRequiredCodeRule(message: "scheduled follow up group needs this field"),
                ScheduledFollowUpGroupRequiredSegmentRule(message: "scheduled follow up group needs an entry"),
                ScheduledFollowUpGroupEndsAtRangeRule(min: 64, max: 1000),
                ScheduledFollowUpGroupRatioRangeRule(min: 5.6, max: 3700.0),
                ScheduledFollowUpGroupRequiredNameRule(message: "scheduled follow up group needs an entry"),
            ]
        )
    }
}
