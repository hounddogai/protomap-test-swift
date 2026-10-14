import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled courier tier must pass. Check returns its problems, or none.
    protocol ScheduledCourierTierRule {
        func check(_ item: ScheduledCourierTier) -> [String]
    }

    final class ScheduledCourierTierTitleLengthRule: ScheduledCourierTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledCourierTier) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledCourierTierRequiredRegionRule: ScheduledCourierTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCourierTier) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCourierTierRevisionRangeRule: ScheduledCourierTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCourierTier) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledCourierTierRequiredTitleRule: ScheduledCourierTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledCourierTier) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ScheduledCourierTierVersionRangeRule: ScheduledCourierTierRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledCourierTier) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a scheduled courier tier.
    final class ScheduledCourierTierValidator {
        var rules: [any ScheduledCourierTierRule]

        init(rules: [any ScheduledCourierTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledCourierTier) -> [String] {
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

        func requireValid(_ item: ScheduledCourierTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledCourierTier]) -> [String: [String]] {
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

    static func defaultScheduledCourierTierValidator() -> ScheduledCourierTierValidator {
        return ScheduledCourierTierValidator(
            rules: [
                ScheduledCourierTierTitleLengthRule(maxLength: 86400),
                ScheduledCourierTierRequiredRegionRule(message: "scheduled courier tier needs this field"),
                ScheduledCourierTierRevisionRangeRule(min: 32, max: 86400),
                ScheduledCourierTierRequiredTitleRule(message: "scheduled courier tier needs this field"),
                ScheduledCourierTierVersionRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
