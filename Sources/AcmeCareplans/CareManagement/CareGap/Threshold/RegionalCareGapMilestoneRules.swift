import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a regional care gap milestone must pass. Check returns its problems, or none.
    protocol RegionalCareGapMilestoneRule {
        func check(_ item: RegionalCareGapMilestone) -> [String]
    }

    final class RegionalCareGapMilestoneRequiredNotesRule: RegionalCareGapMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RegionalCareGapMilestone) -> [String] {
            if item.notes.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RegionalCareGapMilestoneNotesLengthRule: RegionalCareGapMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RegionalCareGapMilestone) -> [String] {
            let size = item.notes.count
            if size > maxLength {
                return ["notes is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RegionalCareGapMilestoneAllowedNotesRule: RegionalCareGapMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RegionalCareGapMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.notes)) {
                return ["notes \(item.notes) is blocked"]
            }
            return []
        }
    }

    final class RegionalCareGapMilestoneMarginRangeRule: RegionalCareGapMilestoneRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RegionalCareGapMilestone) -> [String] {
            let value = item.margin
            var problems: [String] = []
            if value < min {
                problems.append("margin \(value) is below \(min)")
            }
            if value > max {
                problems.append("margin \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a regional care gap milestone.
    final class RegionalCareGapMilestoneValidator {
        var rules: [any RegionalCareGapMilestoneRule]

        init(rules: [any RegionalCareGapMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: RegionalCareGapMilestone) -> [String] {
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

        func requireValid(_ item: RegionalCareGapMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RegionalCareGapMilestone]) -> [String: [String]] {
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

    static func defaultRegionalCareGapMilestoneValidator() -> RegionalCareGapMilestoneValidator {
        return RegionalCareGapMilestoneValidator(
            rules: [
                RegionalCareGapMilestoneRequiredNotesRule(message: "regional care gap milestone needs an entry"),
                RegionalCareGapMilestoneNotesLengthRule(maxLength: 16),
                RegionalCareGapMilestoneAllowedNotesRule(allowed: ["scheduled"]),
                RegionalCareGapMilestoneMarginRangeRule(min: 2.9, max: 4854.0),
            ]
        )
    }
}
