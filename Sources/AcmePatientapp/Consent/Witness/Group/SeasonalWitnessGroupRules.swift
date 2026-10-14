import AcmePlatform
import Foundation

extension Consent {
    /// A rule a seasonal witness group must pass. Check returns its problems, or none.
    protocol SeasonalWitnessGroupRule {
        func check(_ item: SeasonalWitnessGroup) -> [String]
    }

    final class SeasonalWitnessGroupPhoneLengthRule: SeasonalWitnessGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalWitnessGroup) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalWitnessGroupAllowedEncounterIDRule: SeasonalWitnessGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalWitnessGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.encounterID)) {
                return ["encounter id \(item.encounterID) is stale"]
            }
            return []
        }
    }

    final class SeasonalWitnessGroupRequiredNameRule: SeasonalWitnessGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalWitnessGroup) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal witness group.
    final class SeasonalWitnessGroupValidator {
        var rules: [any SeasonalWitnessGroupRule]

        init(rules: [any SeasonalWitnessGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalWitnessGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalWitnessGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalWitnessGroup]) -> [String: [String]] {
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

    static func defaultSeasonalWitnessGroupValidator() -> SeasonalWitnessGroupValidator {
        return SeasonalWitnessGroupValidator(
            rules: [
                SeasonalWitnessGroupPhoneLengthRule(maxLength: 255),
                SeasonalWitnessGroupAllowedEncounterIDRule(allowed: []),
                SeasonalWitnessGroupRequiredNameRule(message: "seasonal witness group needs an entry"),
            ]
        )
    }
}
