import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a scheduled follow up cycle must pass. Check returns its problems, or none.
    protocol ScheduledFollowUpCycleRule {
        func check(_ item: ScheduledFollowUpCycle) -> [String]
    }

    final class ScheduledFollowUpCycleTitleLengthRule: ScheduledFollowUpCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledFollowUpCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpCycleCodePrefixRule: ScheduledFollowUpCycleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ScheduledFollowUpCycle) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpCycleVisitMinutesRangeRule: ScheduledFollowUpCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledFollowUpCycle) -> [String] {
            let value = item.visitMinutes
            if value < min || value > max {
                return ["visit minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledFollowUpCycleAllowedCodeRule: ScheduledFollowUpCycleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ScheduledFollowUpCycle) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled follow up cycle.
    final class ScheduledFollowUpCycleValidator {
        var rules: [any ScheduledFollowUpCycleRule]

        init(rules: [any ScheduledFollowUpCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledFollowUpCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ScheduledFollowUpCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledFollowUpCycle]) -> [String: [String]] {
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

    static func defaultScheduledFollowUpCycleValidator() -> ScheduledFollowUpCycleValidator {
        return ScheduledFollowUpCycleValidator(
            rules: [
                ScheduledFollowUpCycleTitleLengthRule(maxLength: 120),
                ScheduledFollowUpCycleCodePrefixRule(prefix: "X"),
                ScheduledFollowUpCycleVisitMinutesRangeRule(min: 32, max: 120),
                ScheduledFollowUpCycleAllowedCodeRule(allowed: ["batched"]),
            ]
        )
    }
}
