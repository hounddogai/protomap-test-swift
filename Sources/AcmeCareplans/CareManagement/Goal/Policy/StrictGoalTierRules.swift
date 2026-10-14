import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a strict goal tier must pass. Check returns its problems, or none.
    protocol StrictGoalTierRule {
        func check(_ item: StrictGoalTier) -> [String]
    }

    final class StrictGoalTierRequiredEncounterIDRule: StrictGoalTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictGoalTier) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictGoalTierPatientRefLengthRule: StrictGoalTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictGoalTier) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictGoalTierEncounterIDLengthRule: StrictGoalTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictGoalTier) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictGoalTierRequiredPatientRefRule: StrictGoalTierRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictGoalTier) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictGoalTierNameLengthRule: StrictGoalTierRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictGoalTier) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict goal tier.
    final class StrictGoalTierValidator {
        var rules: [any StrictGoalTierRule]

        init(rules: [any StrictGoalTierRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictGoalTier) -> [String] {
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

        func requireValid(_ item: StrictGoalTier) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictGoalTier]) -> [String: [String]] {
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

    static func defaultStrictGoalTierValidator() -> StrictGoalTierValidator {
        return StrictGoalTierValidator(
            rules: [
                StrictGoalTierRequiredEncounterIDRule(message: "strict goal tier needs a value"),
                StrictGoalTierPatientRefLengthRule(maxLength: 1000),
                StrictGoalTierEncounterIDLengthRule(maxLength: 16),
                StrictGoalTierRequiredPatientRefRule(message: "strict goal tier needs this field"),
                StrictGoalTierNameLengthRule(maxLength: 86400),
            ]
        )
    }
}
