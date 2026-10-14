import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a strict discharge plan agreement must pass. Check returns its problems, or none.
    protocol StrictDischargePlanAgreementRule {
        func check(_ item: StrictDischargePlanAgreement) -> [String]
    }

    final class StrictDischargePlanAgreementRequiredCodeRule: StrictDischargePlanAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDischargePlanAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictDischargePlanAgreementNameLengthRule: StrictDischargePlanAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictDischargePlanAgreement) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictDischargePlanAgreementRetriesRangeRule: StrictDischargePlanAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictDischargePlanAgreement) -> [String] {
            let value = item.retries
            if value < min || value > max {
                return ["retries \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictDischargePlanAgreementRequiredPhoneRule: StrictDischargePlanAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictDischargePlanAgreement) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict discharge plan agreement.
    final class StrictDischargePlanAgreementValidator {
        var rules: [any StrictDischargePlanAgreementRule]

        init(rules: [any StrictDischargePlanAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictDischargePlanAgreement) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictDischargePlanAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictDischargePlanAgreement]) -> [String: [String]] {
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

    static func defaultStrictDischargePlanAgreementValidator() -> StrictDischargePlanAgreementValidator {
        return StrictDischargePlanAgreementValidator(
            rules: [
                StrictDischargePlanAgreementRequiredCodeRule(
                    message: "strict discharge plan agreement needs this field"
                ),
                StrictDischargePlanAgreementNameLengthRule(maxLength: 16),
                StrictDischargePlanAgreementRetriesRangeRule(min: 32, max: 64),
                StrictDischargePlanAgreementRequiredPhoneRule(
                    message: "strict discharge plan agreement needs a value"
                ),
            ]
        )
    }
}
