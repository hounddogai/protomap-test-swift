import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a seasonal statement agreement must pass. Check returns its problems, or none.
    protocol SeasonalStatementAgreementRule {
        func check(_ item: SeasonalStatementAgreement) -> [String]
    }

    final class SeasonalStatementAgreementExpiresAtRangeRule: SeasonalStatementAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStatementAgreement) -> [String] {
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

    final class SeasonalStatementAgreementRequiredNameRule: SeasonalStatementAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStatementAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStatementAgreementRequiredCodeRule: SeasonalStatementAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStatementAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalStatementAgreementPriorityRangeRule: SeasonalStatementAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalStatementAgreement) -> [String] {
            let value = item.priority
            var problems: [String] = []
            if value < min {
                problems.append("priority \(value) is below \(min)")
            }
            if value > max {
                problems.append("priority \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalStatementAgreementNameLengthRule: SeasonalStatementAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalStatementAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalStatementAgreementRequiredCurrencyRule: SeasonalStatementAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalStatementAgreement) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal statement agreement.
    final class SeasonalStatementAgreementValidator {
        var rules: [any SeasonalStatementAgreementRule]

        init(rules: [any SeasonalStatementAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalStatementAgreement) -> [String] {
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

        func requireValid(_ item: SeasonalStatementAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalStatementAgreement]) -> [String: [String]] {
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

    static func defaultSeasonalStatementAgreementValidator() -> SeasonalStatementAgreementValidator {
        return SeasonalStatementAgreementValidator(
            rules: [
                SeasonalStatementAgreementExpiresAtRangeRule(min: 16, max: 32),
                SeasonalStatementAgreementRequiredNameRule(message: "seasonal statement agreement needs this field"),
                SeasonalStatementAgreementRequiredCodeRule(message: "seasonal statement agreement needs a value"),
                SeasonalStatementAgreementPriorityRangeRule(min: 32, max: 86400),
                SeasonalStatementAgreementNameLengthRule(maxLength: 80),
                SeasonalStatementAgreementRequiredCurrencyRule(message: "seasonal statement agreement needs a value"),
            ]
        )
    }
}
