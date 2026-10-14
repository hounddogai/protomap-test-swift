import AcmePlatform
import Foundation

extension Consent {
    /// A rule a legacy witness group must pass. Check returns its problems, or none.
    protocol LegacyWitnessGroupRule {
        func check(_ item: LegacyWitnessGroup) -> [String]
    }

    final class LegacyWitnessGroupRequiredCodeRule: LegacyWitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyWitnessGroup) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyWitnessGroupRequiredTitleRule: LegacyWitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyWitnessGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyWitnessGroupPatientRefLengthRule: LegacyWitnessGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyWitnessGroup) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacyWitnessGroupRequiredPatientRefRule: LegacyWitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyWitnessGroup) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy witness group.
    final class LegacyWitnessGroupValidator {
        var rules: [any LegacyWitnessGroupRule]

        init(rules: [any LegacyWitnessGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyWitnessGroup) -> [String] {
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

        func requireValid(_ item: LegacyWitnessGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyWitnessGroup]) -> [String: [String]] {
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

    static func defaultLegacyWitnessGroupValidator() -> LegacyWitnessGroupValidator {
        return LegacyWitnessGroupValidator(
            rules: [
                LegacyWitnessGroupRequiredCodeRule(message: "legacy witness group needs this field"),
                LegacyWitnessGroupRequiredTitleRule(message: "legacy witness group needs an entry"),
                LegacyWitnessGroupPatientRefLengthRule(maxLength: 32),
                LegacyWitnessGroupRequiredPatientRefRule(message: "legacy witness group needs a value"),
            ]
        )
    }
}
