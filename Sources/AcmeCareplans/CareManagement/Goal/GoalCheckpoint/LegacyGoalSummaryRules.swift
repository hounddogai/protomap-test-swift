import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy goal summary must pass. Check returns its problems, or none.
    protocol LegacyGoalSummaryRule {
        func check(_ item: LegacyGoalSummary) -> [String]
    }

    final class LegacyGoalSummaryPriorityRangeRule: LegacyGoalSummaryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyGoalSummary) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyGoalSummaryPatientRefLengthRule: LegacyGoalSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyGoalSummary) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyGoalSummaryRequiredPatientRefRule: LegacyGoalSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyGoalSummary) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyGoalSummaryEncounterIDLengthRule: LegacyGoalSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyGoalSummary) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyGoalSummaryRequiredEncounterIDRule: LegacyGoalSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyGoalSummary) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy goal summary.
    final class LegacyGoalSummaryValidator {
        var rules: [any LegacyGoalSummaryRule]

        init(rules: [any LegacyGoalSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyGoalSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyGoalSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyGoalSummary]) -> [String: [String]] {
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

    static func defaultLegacyGoalSummaryValidator() -> LegacyGoalSummaryValidator {
        return LegacyGoalSummaryValidator(
            rules: [
                LegacyGoalSummaryPriorityRangeRule(min: 32, max: 64),
                LegacyGoalSummaryPatientRefLengthRule(maxLength: 80),
                LegacyGoalSummaryRequiredPatientRefRule(message: "legacy goal summary needs an entry"),
                LegacyGoalSummaryEncounterIDLengthRule(maxLength: 120),
                LegacyGoalSummaryRequiredEncounterIDRule(message: "legacy goal summary needs this field"),
            ]
        )
    }
}
