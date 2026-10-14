import AcmePlatform
import Foundation

extension Labs {
    /// A rule a scheduled specimen tier must pass. Check returns its problems, or none.
    protocol ScheduledSpecimenTierRule {
        func check(_ item: ScheduledSpecimenTier) -> [String]
    }

    final class ScheduledSpecimenTierDescriptionLengthRule: ScheduledSpecimenTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledSpecimenTier) -> [String] {
            let size = item.description.count
            if size > maxLength {
                return ["description is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledSpecimenTierCodeLengthRule: ScheduledSpecimenTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ScheduledSpecimenTier) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ScheduledSpecimenTierCeilingRangeRule: ScheduledSpecimenTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledSpecimenTier) -> [String] {
            let value = item.ceiling
            if value < min || value > max {
                return ["ceiling \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ScheduledSpecimenTierMaximumRangeRule: ScheduledSpecimenTierRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ScheduledSpecimenTier) -> [String] {
            let value = item.maximum
            var problems: [String] = []
            if value < min {
                problems.append("maximum \(value) is below \(min)")
            }
            if value > max {
                problems.append("maximum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ScheduledSpecimenTierRequiredCodeRule: ScheduledSpecimenTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ScheduledSpecimenTier) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a scheduled specimen tier.
    final class ScheduledSpecimenTierValidator {
        var rules: [any ScheduledSpecimenTierRule]

        init(rules: [any ScheduledSpecimenTierRule]) {
            self.rules = rules
        }

        func validate(_ item: ScheduledSpecimenTier) -> [String] {
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

        func requireValid(_ item: ScheduledSpecimenTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ScheduledSpecimenTier]) -> [String: [String]] {
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

    static func defaultScheduledSpecimenTierValidator() -> ScheduledSpecimenTierValidator {
        return ScheduledSpecimenTierValidator(
            rules: [
                ScheduledSpecimenTierDescriptionLengthRule(maxLength: 1000),
                ScheduledSpecimenTierCodeLengthRule(maxLength: 16),
                ScheduledSpecimenTierCeilingRangeRule(min: 4.1, max: 3885.9),
                ScheduledSpecimenTierMaximumRangeRule(min: 3.8, max: 3787.7),
                ScheduledSpecimenTierRequiredCodeRule(message: "scheduled specimen tier needs a value"),
            ]
        )
    }
}
