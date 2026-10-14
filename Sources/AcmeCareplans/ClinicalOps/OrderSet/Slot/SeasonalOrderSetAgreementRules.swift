import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a seasonal order set agreement must pass. Check returns its problems, or none.
    protocol SeasonalOrderSetAgreementRule {
        func check(_ item: SeasonalOrderSetAgreement) -> [String]
    }

    final class SeasonalOrderSetAgreementCodeLengthRule: SeasonalOrderSetAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOrderSetAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOrderSetAgreementLabelLengthRule: SeasonalOrderSetAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalOrderSetAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalOrderSetAgreementRequiredCodeRule: SeasonalOrderSetAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalOrderSetAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal order set agreement.
    final class SeasonalOrderSetAgreementValidator {
        var rules: [any SeasonalOrderSetAgreementRule]

        init(rules: [any SeasonalOrderSetAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalOrderSetAgreement) -> [String] {
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

        func requireValid(_ item: SeasonalOrderSetAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalOrderSetAgreement]) -> [String: [String]] {
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

    static func defaultSeasonalOrderSetAgreementValidator() -> SeasonalOrderSetAgreementValidator {
        return SeasonalOrderSetAgreementValidator(
            rules: [
                SeasonalOrderSetAgreementCodeLengthRule(maxLength: 120),
                SeasonalOrderSetAgreementLabelLengthRule(maxLength: 255),
                SeasonalOrderSetAgreementRequiredCodeRule(message: "seasonal order set agreement needs this field"),
            ]
        )
    }
}
