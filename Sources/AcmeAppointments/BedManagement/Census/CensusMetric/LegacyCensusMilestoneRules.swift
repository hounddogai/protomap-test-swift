import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a legacy census milestone must pass. Check returns its problems, or none.
    protocol LegacyCensusMilestoneRule {
        func check(_ item: LegacyCensusMilestone) -> [String]
    }

    final class LegacyCensusMilestoneNameLengthRule: LegacyCensusMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyCensusMilestone) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyCensusMilestoneBudgetRangeRule: LegacyCensusMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCensusMilestone) -> [String] {
            let value = item.budget
            if value < min || value > max {
                return ["budget \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyCensusMilestoneFloorValueRangeRule: LegacyCensusMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyCensusMilestone) -> [String] {
            let value = item.floorValue
            var problems: [String] = []
            if value < min {
                problems.append("floor value \(value) is below \(min)")
            }
            if value > max {
                problems.append("floor value \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyCensusMilestoneRequiredLocaleRule: LegacyCensusMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCensusMilestone) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyCensusMilestoneRequiredCategoryRule: LegacyCensusMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyCensusMilestone) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy census milestone.
    final class LegacyCensusMilestoneValidator {
        var rules: [any LegacyCensusMilestoneRule]

        init(rules: [any LegacyCensusMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyCensusMilestone) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyCensusMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyCensusMilestone]) -> [String: [String]] {
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

    static func defaultLegacyCensusMilestoneValidator() -> LegacyCensusMilestoneValidator {
        return LegacyCensusMilestoneValidator(
            rules: [
                LegacyCensusMilestoneNameLengthRule(maxLength: 80),
                LegacyCensusMilestoneBudgetRangeRule(min: 6.0, max: 4283.7),
                LegacyCensusMilestoneFloorValueRangeRule(min: 2.8, max: 984.5),
                LegacyCensusMilestoneRequiredLocaleRule(message: "legacy census milestone needs an entry"),
                LegacyCensusMilestoneRequiredCategoryRule(message: "legacy census milestone needs this field"),
            ]
        )
    }
}
