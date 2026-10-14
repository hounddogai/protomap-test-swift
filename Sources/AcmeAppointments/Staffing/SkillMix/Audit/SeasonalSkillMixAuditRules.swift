import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a seasonal skill mix audit must pass. Check returns its problems, or none.
    protocol SeasonalSkillMixAuditRule {
        func check(_ item: SeasonalSkillMixAudit) -> [String]
    }

    final class SeasonalSkillMixAuditRequiredWardRule: SeasonalSkillMixAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixAudit) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSkillMixAuditExpiresAtRangeRule: SeasonalSkillMixAuditRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixAudit) -> [String] {
            let value = item.expiresAt
            var problems: [String] = []
            if value < min {
                problems.append("expires at \(value) is below \(min)")
            }
            if value > max {
                problems.append("expires at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSkillMixAuditDosageMgRangeRule: SeasonalSkillMixAuditRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSkillMixAudit) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSkillMixAuditFacilityLengthRule: SeasonalSkillMixAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixAudit) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixAuditWardLengthRule: SeasonalSkillMixAuditRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSkillMixAudit) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSkillMixAuditRequiredTitleRule: SeasonalSkillMixAuditRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSkillMixAudit) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal skill mix audit.
    final class SeasonalSkillMixAuditValidator {
        var rules: [any SeasonalSkillMixAuditRule]

        init(rules: [any SeasonalSkillMixAuditRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSkillMixAudit) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSkillMixAudit) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSkillMixAudit]) -> [String: [String]] {
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

    static func defaultSeasonalSkillMixAuditValidator() -> SeasonalSkillMixAuditValidator {
        return SeasonalSkillMixAuditValidator(
            rules: [
                SeasonalSkillMixAuditRequiredWardRule(message: "seasonal skill mix audit needs a value"),
                SeasonalSkillMixAuditExpiresAtRangeRule(min: 16, max: 32),
                SeasonalSkillMixAuditDosageMgRangeRule(min: 6.4, max: 2682.9),
                SeasonalSkillMixAuditFacilityLengthRule(maxLength: 80),
                SeasonalSkillMixAuditWardLengthRule(maxLength: 86400),
                SeasonalSkillMixAuditRequiredTitleRule(message: "seasonal skill mix audit needs an entry"),
            ]
        )
    }
}
