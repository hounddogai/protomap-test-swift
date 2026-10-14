import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal statement rule must pass. Check returns its problems, or none.
    protocol SeasonalStatementRuleRule {
        func check(_ item: SeasonalStatementRule) -> [String]
    }

    final class SeasonalStatementRuleEncounterIDLengthRule: SeasonalStatementRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStatementRule) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalStatementRuleRequiredTitleRule: SeasonalStatementRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStatementRule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStatementRuleCodeLengthRule: SeasonalStatementRuleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStatementRule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalStatementRuleRequiredEncounterIDRule: SeasonalStatementRuleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStatementRule) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal statement rule.
    final class SeasonalStatementRuleValidator {
        var rules: [any SeasonalStatementRuleRule]

        init(rules: [any SeasonalStatementRuleRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalStatementRule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalStatementRule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalStatementRule]) -> [String: [String]] {
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

    static func defaultSeasonalStatementRuleValidator() -> SeasonalStatementRuleValidator {
        return SeasonalStatementRuleValidator(
            rules: [
                SeasonalStatementRuleEncounterIDLengthRule(maxLength: 32),
                SeasonalStatementRuleRequiredTitleRule(message: "seasonal statement rule needs an entry"),
                SeasonalStatementRuleCodeLengthRule(maxLength: 32),
                SeasonalStatementRuleRequiredEncounterIDRule(message: "seasonal statement rule needs this field"),
            ]
        )
    }
}
