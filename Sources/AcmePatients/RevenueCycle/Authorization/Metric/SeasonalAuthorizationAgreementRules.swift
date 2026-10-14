import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal authorization agreement must pass. Check returns its problems, or none.
    protocol SeasonalAuthorizationAgreementRule {
        func check(_ item: SeasonalAuthorizationAgreement) -> [String]
    }

    final class SeasonalAuthorizationAgreementAllowedTitleRule: SeasonalAuthorizationAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: SeasonalAuthorizationAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is above maximum"]
            }
            return []
        }
    }

    final class SeasonalAuthorizationAgreementRequiredEncounterIDRule: SeasonalAuthorizationAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalAuthorizationAgreement) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalAuthorizationAgreementTitleLengthRule: SeasonalAuthorizationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAuthorizationAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalAuthorizationAgreementEndsAtRangeRule: SeasonalAuthorizationAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalAuthorizationAgreement) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalAuthorizationAgreementCodeLengthRule: SeasonalAuthorizationAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalAuthorizationAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal authorization agreement.
    final class SeasonalAuthorizationAgreementValidator {
        var rules: [any SeasonalAuthorizationAgreementRule]

        init(rules: [any SeasonalAuthorizationAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalAuthorizationAgreement) -> [String] {
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

        func requireValid(_ item: SeasonalAuthorizationAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalAuthorizationAgreement]) -> [String: [String]] {
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

    static func defaultSeasonalAuthorizationAgreementValidator() -> SeasonalAuthorizationAgreementValidator {
        return SeasonalAuthorizationAgreementValidator(
            rules: [
                SeasonalAuthorizationAgreementAllowedTitleRule(allowed: ["seasonal"]),
                SeasonalAuthorizationAgreementRequiredEncounterIDRule(
                    message: "seasonal authorization agreement needs an entry"
                ),
                SeasonalAuthorizationAgreementTitleLengthRule(maxLength: 16),
                SeasonalAuthorizationAgreementEndsAtRangeRule(min: 120, max: 1000),
                SeasonalAuthorizationAgreementCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
