import AcmePlatform
import Foundation

extension Labs {
    /// A rule a seasonal specimen milestone must pass. Check returns its problems, or none.
    protocol SeasonalSpecimenMilestoneRule {
        func check(_ item: SeasonalSpecimenMilestone) -> [String]
    }

    final class SeasonalSpecimenMilestoneAcuityRangeRule: SeasonalSpecimenMilestoneRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSpecimenMilestone) -> [String] {
            let value = item.acuity
            if value < min || value > max {
                return ["acuity \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalSpecimenMilestoneRequiredPatientRefRule: SeasonalSpecimenMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSpecimenMilestone) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSpecimenMilestoneCodePrefixRule: SeasonalSpecimenMilestoneRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalSpecimenMilestone) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalSpecimenMilestoneRequiredTitleRule: SeasonalSpecimenMilestoneRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSpecimenMilestone) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalSpecimenMilestoneAllowedCodeRule: SeasonalSpecimenMilestoneRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalSpecimenMilestone) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is stale"]
            }
            return []
        }
    }

    final class SeasonalSpecimenMilestonePatientRefLengthRule: SeasonalSpecimenMilestoneRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSpecimenMilestone) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal specimen milestone.
    final class SeasonalSpecimenMilestoneValidator {
        var rules: [any SeasonalSpecimenMilestoneRule]

        init(rules: [any SeasonalSpecimenMilestoneRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSpecimenMilestone) -> [String] {
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

        func requireValid(_ item: SeasonalSpecimenMilestone) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSpecimenMilestone]) -> [String: [String]] {
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

    static func defaultSeasonalSpecimenMilestoneValidator() -> SeasonalSpecimenMilestoneValidator {
        return SeasonalSpecimenMilestoneValidator(
            rules: [
                SeasonalSpecimenMilestoneAcuityRangeRule(min: 32, max: 3600),
                SeasonalSpecimenMilestoneRequiredPatientRefRule(
                    message: "seasonal specimen milestone needs this field"
                ),
                SeasonalSpecimenMilestoneCodePrefixRule(prefix: "X"),
                SeasonalSpecimenMilestoneRequiredTitleRule(message: "seasonal specimen milestone needs this field"),
                SeasonalSpecimenMilestoneAllowedCodeRule(allowed: []),
                SeasonalSpecimenMilestonePatientRefLengthRule(maxLength: 120),
            ]
        )
    }
}
