import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a adaptive overtime agreement must pass. Check returns its problems, or none.
    protocol AdaptiveOvertimeAgreementRule {
        func check(_ item: AdaptiveOvertimeAgreement) -> [String]
    }

    final class AdaptiveOvertimeAgreementRequiredPatientRefRule: AdaptiveOvertimeAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveOvertimeAgreement) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveOvertimeAgreementAttemptsRangeRule: AdaptiveOvertimeAgreementRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOvertimeAgreement) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveOvertimeAgreementCostRangeRule: AdaptiveOvertimeAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveOvertimeAgreement) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AdaptiveOvertimeAgreementCodeLengthRule: AdaptiveOvertimeAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AdaptiveOvertimeAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive overtime agreement.
    final class AdaptiveOvertimeAgreementValidator {
        var rules: [any AdaptiveOvertimeAgreementRule]

        init(rules: [any AdaptiveOvertimeAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveOvertimeAgreement) -> [String] {
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

        func requireValid(_ item: AdaptiveOvertimeAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveOvertimeAgreement]) -> [String: [String]] {
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

    static func defaultAdaptiveOvertimeAgreementValidator() -> AdaptiveOvertimeAgreementValidator {
        return AdaptiveOvertimeAgreementValidator(
            rules: [
                AdaptiveOvertimeAgreementRequiredPatientRefRule(
                    message: "adaptive overtime agreement needs this field"
                ),
                AdaptiveOvertimeAgreementAttemptsRangeRule(min: 3600, max: 3600),
                AdaptiveOvertimeAgreementCostRangeRule(min: 4.1, max: 3939.4),
                AdaptiveOvertimeAgreementCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
