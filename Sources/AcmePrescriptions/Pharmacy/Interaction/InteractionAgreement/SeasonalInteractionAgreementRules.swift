import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal interaction agreement must pass. Check returns its problems, or none.
    protocol SeasonalInteractionAgreementRule {
        func check(_ item: SeasonalInteractionAgreement) -> [String]
    }

    final class SeasonalInteractionAgreementLimitRangeRule: SeasonalInteractionAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalInteractionAgreement) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class SeasonalInteractionAgreementNameLengthRule: SeasonalInteractionAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalInteractionAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalInteractionAgreementRequiredNameRule: SeasonalInteractionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInteractionAgreement) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInteractionAgreementRequiredLabelRule: SeasonalInteractionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInteractionAgreement) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SeasonalInteractionAgreementRequiredCodeRule: SeasonalInteractionAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalInteractionAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal interaction agreement.
    final class SeasonalInteractionAgreementValidator {
        var rules: [any SeasonalInteractionAgreementRule]

        init(rules: [any SeasonalInteractionAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalInteractionAgreement) -> [String] {
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

        func requireValid(_ item: SeasonalInteractionAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalInteractionAgreement]) -> [String: [String]] {
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

    static func defaultSeasonalInteractionAgreementValidator() -> SeasonalInteractionAgreementValidator {
        return SeasonalInteractionAgreementValidator(
            rules: [
                SeasonalInteractionAgreementLimitRangeRule(min: 80, max: 1000),
                SeasonalInteractionAgreementNameLengthRule(maxLength: 86400),
                SeasonalInteractionAgreementRequiredNameRule(message: "seasonal interaction agreement needs an entry"),
                SeasonalInteractionAgreementRequiredLabelRule(
                    message: "seasonal interaction agreement needs an entry"
                ),
                SeasonalInteractionAgreementRequiredCodeRule(message: "seasonal interaction agreement needs a value"),
            ]
        )
    }
}
