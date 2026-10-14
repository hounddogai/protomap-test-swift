import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a discharge plan agreement must pass. Check returns its problems, or none.
    protocol DischargePlanAgreementRule {
        func check(_ item: DischargePlanAgreement) -> [String]
    }

    final class DischargePlanAgreementCodePrefixRule: DischargePlanAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DischargePlanAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DischargePlanAgreementUpdatedAtRangeRule: DischargePlanAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DischargePlanAgreement) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class DischargePlanAgreementRequiredLabelRule: DischargePlanAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanAgreement) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanAgreementRequiredCountryRule: DischargePlanAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DischargePlanAgreement) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DischargePlanAgreementCodeLengthRule: DischargePlanAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DischargePlanAgreementLabelLengthRule: DischargePlanAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DischargePlanAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a discharge plan agreement.
    final class DischargePlanAgreementValidator {
        var rules: [any DischargePlanAgreementRule]

        init(rules: [any DischargePlanAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: DischargePlanAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DischargePlanAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DischargePlanAgreement]) -> [String: [String]] {
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

    static func defaultDischargePlanAgreementValidator() -> DischargePlanAgreementValidator {
        return DischargePlanAgreementValidator(
            rules: [
                DischargePlanAgreementCodePrefixRule(prefix: "X"),
                DischargePlanAgreementUpdatedAtRangeRule(min: 16, max: 120),
                DischargePlanAgreementRequiredLabelRule(message: "discharge plan agreement needs this field"),
                DischargePlanAgreementRequiredCountryRule(message: "discharge plan agreement needs an entry"),
                DischargePlanAgreementCodeLengthRule(maxLength: 64),
                DischargePlanAgreementLabelLengthRule(maxLength: 120),
            ]
        )
    }
}
