import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a scheduled worklist tier must pass. Check returns its problems, or none.
    protocol ScheduledWorklistTierRule {
        func check(_ item: ScheduledWorklistTier) -> [String]
    }

    final class ScheduledWorklistTierDurationMinutesRangeRule: ScheduledWorklistTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledWorklistTier) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledWorklistTierCodeLengthRule: ScheduledWorklistTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledWorklistTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledWorklistTierRequiredCodeRule: ScheduledWorklistTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledWorklistTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled worklist tier.
    final class ScheduledWorklistTierValidator {
        var rules: [any ScheduledWorklistTierRule]

        init(rules: [any ScheduledWorklistTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledWorklistTier) -> [String] {
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

        func requireValid(_ item: ScheduledWorklistTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledWorklistTier]) -> [String: [String]] {
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

    static func defaultScheduledWorklistTierValidator() -> ScheduledWorklistTierValidator {
        return ScheduledWorklistTierValidator(
            rules: [
                ScheduledWorklistTierDurationMinutesRangeRule(min: 255, max: 1000),
                ScheduledWorklistTierCodeLengthRule(maxLength: 32),
                ScheduledWorklistTierRequiredCodeRule(message: "scheduled worklist tier needs a value"),
            ]
        )
    }
}
