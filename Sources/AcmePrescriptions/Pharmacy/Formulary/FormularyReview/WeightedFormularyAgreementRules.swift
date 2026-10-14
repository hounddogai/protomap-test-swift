import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted formulary agreement must pass. Check returns its problems, or none.
    protocol WeightedFormularyAgreementRule {
        func check(_ item: WeightedFormularyAgreement) -> [String]
    }

    final class WeightedFormularyAgreementCodePrefixRule: WeightedFormularyAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: WeightedFormularyAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class WeightedFormularyAgreementDurationMinutesRangeRule: WeightedFormularyAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedFormularyAgreement) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedFormularyAgreementRequiredEncounterIDRule: WeightedFormularyAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyAgreement) -> [String] {
            if item.encounterID.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedFormularyAgreementSpecialtyLengthRule: WeightedFormularyAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedFormularyAgreement) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedFormularyAgreementRequiredCodeRule: WeightedFormularyAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedFormularyAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted formulary agreement.
    final class WeightedFormularyAgreementValidator {
        var rules: [any WeightedFormularyAgreementRule]

        init(rules: [any WeightedFormularyAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedFormularyAgreement) -> [String] {
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

        func requireValid(_ item: WeightedFormularyAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedFormularyAgreement]) -> [String: [String]] {
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

    static func defaultWeightedFormularyAgreementValidator() -> WeightedFormularyAgreementValidator {
        return WeightedFormularyAgreementValidator(
            rules: [
                WeightedFormularyAgreementCodePrefixRule(prefix: "OPS"),
                WeightedFormularyAgreementDurationMinutesRangeRule(min: 16, max: 120),
                WeightedFormularyAgreementRequiredEncounterIDRule(
                    message: "weighted formulary agreement needs this field"
                ),
                WeightedFormularyAgreementSpecialtyLengthRule(maxLength: 1000),
                WeightedFormularyAgreementRequiredCodeRule(message: "weighted formulary agreement needs an entry"),
            ]
        )
    }
}
