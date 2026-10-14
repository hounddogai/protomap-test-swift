import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a seasonal read milestone must pass. Check returns its problems, or none.
    protocol SeasonalReadMilestoneRule {
        func check(_ item: SeasonalReadMilestone) -> [String]
    }

    final class SeasonalReadMilestoneCountryLengthRule: SeasonalReadMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalReadMilestone) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalReadMilestoneCapacityRangeRule: SeasonalReadMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalReadMilestone) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalReadMilestoneRequiredUnitRule: SeasonalReadMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReadMilestone) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalReadMilestoneAllowedFacilityRule: SeasonalReadMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalReadMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.facility)) {
                return ["facility \(item.facility) is not allowed"]
            }
            return []
        }
    }

    final class SeasonalReadMilestoneRequiredCodeRule: SeasonalReadMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalReadMilestone) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal read milestone.
    final class SeasonalReadMilestoneValidator {
        var rules: [any SeasonalReadMilestoneRule]

        init(rules: [any SeasonalReadMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalReadMilestone) -> [String] {
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

        func requireValid(_ item: SeasonalReadMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalReadMilestone]) -> [String: [String]] {
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

    static func defaultSeasonalReadMilestoneValidator() -> SeasonalReadMilestoneValidator {
        return SeasonalReadMilestoneValidator(
            rules: [
                SeasonalReadMilestoneCountryLengthRule(maxLength: 1000),
                SeasonalReadMilestoneCapacityRangeRule(min: 32, max: 3600),
                SeasonalReadMilestoneRequiredUnitRule(message: "seasonal read milestone needs this field"),
                SeasonalReadMilestoneAllowedFacilityRule(allowed: ["lenient"]),
                SeasonalReadMilestoneRequiredCodeRule(message: "seasonal read milestone needs a value"),
            ]
        )
    }
}
