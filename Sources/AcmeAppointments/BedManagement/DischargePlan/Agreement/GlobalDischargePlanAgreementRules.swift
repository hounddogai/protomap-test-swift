import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a global discharge plan agreement must pass. Check returns its problems, or none.
    protocol GlobalDischargePlanAgreementRule {
        func check(_ item: GlobalDischargePlanAgreement) -> [String]
    }

    final class GlobalDischargePlanAgreementRequiredPayerRule: GlobalDischargePlanAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDischargePlanAgreement) -> [String] {
            if item.payer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDischargePlanAgreementRefillsRangeRule: GlobalDischargePlanAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalDischargePlanAgreement) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalDischargePlanAgreementCodePrefixRule: GlobalDischargePlanAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: GlobalDischargePlanAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class GlobalDischargePlanAgreementRequiredLabelRule: GlobalDischargePlanAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalDischargePlanAgreement) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalDischargePlanAgreementLabelLengthRule: GlobalDischargePlanAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalDischargePlanAgreement) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global discharge plan agreement.
    final class GlobalDischargePlanAgreementValidator {
        var rules: [any GlobalDischargePlanAgreementRule]

        init(rules: [any GlobalDischargePlanAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalDischargePlanAgreement) -> [String] {
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

        func requireValid(_ item: GlobalDischargePlanAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalDischargePlanAgreement]) -> [String: [String]] {
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

    static func defaultGlobalDischargePlanAgreementValidator() -> GlobalDischargePlanAgreementValidator {
        return GlobalDischargePlanAgreementValidator(
            rules: [
                GlobalDischargePlanAgreementRequiredPayerRule(
                    message: "global discharge plan agreement needs this field"
                ),
                GlobalDischargePlanAgreementRefillsRangeRule(min: 32, max: 1000),
                GlobalDischargePlanAgreementCodePrefixRule(prefix: "OPS"),
                GlobalDischargePlanAgreementRequiredLabelRule(
                    message: "global discharge plan agreement needs this field"
                ),
                GlobalDischargePlanAgreementLabelLengthRule(maxLength: 255),
            ]
        )
    }
}
