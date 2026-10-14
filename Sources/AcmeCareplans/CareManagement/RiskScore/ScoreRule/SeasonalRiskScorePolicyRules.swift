import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a seasonal risk score policy must pass. Check returns its problems, or none.
    protocol SeasonalRiskScorePolicyRule {
        func check(_ item: SeasonalRiskScorePolicy) -> [String]
    }

    final class SeasonalRiskScorePolicyCountryLengthRule: SeasonalRiskScorePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRiskScorePolicy) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalRiskScorePolicyRequiredCodeRule: SeasonalRiskScorePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRiskScorePolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRiskScorePolicyRequiredCountryRule: SeasonalRiskScorePolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalRiskScorePolicy) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalRiskScorePolicyCodePrefixRule: SeasonalRiskScorePolicyRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: SeasonalRiskScorePolicy) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class SeasonalRiskScorePolicyNameLengthRule: SeasonalRiskScorePolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalRiskScorePolicy) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal risk score policy.
    final class SeasonalRiskScorePolicyValidator {
        var rules: [any SeasonalRiskScorePolicyRule]

        init(rules: [any SeasonalRiskScorePolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalRiskScorePolicy) -> [String] {
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

        func requireValid(_ item: SeasonalRiskScorePolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalRiskScorePolicy]) -> [String: [String]] {
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

    static func defaultSeasonalRiskScorePolicyValidator() -> SeasonalRiskScorePolicyValidator {
        return SeasonalRiskScorePolicyValidator(
            rules: [
                SeasonalRiskScorePolicyCountryLengthRule(maxLength: 3600),
                SeasonalRiskScorePolicyRequiredCodeRule(message: "seasonal risk score policy needs a value"),
                SeasonalRiskScorePolicyRequiredCountryRule(message: "seasonal risk score policy needs this field"),
                SeasonalRiskScorePolicyCodePrefixRule(prefix: "X"),
                SeasonalRiskScorePolicyNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
