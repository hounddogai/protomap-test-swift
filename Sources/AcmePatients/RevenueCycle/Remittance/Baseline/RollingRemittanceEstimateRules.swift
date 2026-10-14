import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a rolling remittance estimate must pass. Check returns its problems, or none.
    protocol RollingRemittanceEstimateRule {
        func check(_ item: RollingRemittanceEstimate) -> [String]
    }

    final class RollingRemittanceEstimateLabelLengthRule: RollingRemittanceEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRemittanceEstimate) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingRemittanceEstimateRequiredCurrencyRule: RollingRemittanceEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRemittanceEstimate) -> [String] {
            if item.currency.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRemittanceEstimateAllowedPatientRefRule: RollingRemittanceEstimateRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingRemittanceEstimate) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.patientRef)) {
                return ["patient ref \(item.patientRef) is duplicated"]
            }
            return []
        }
    }

    final class RollingRemittanceEstimateRequiredPatientRefRule: RollingRemittanceEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingRemittanceEstimate) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingRemittanceEstimateCodeLengthRule: RollingRemittanceEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingRemittanceEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling remittance estimate.
    final class RollingRemittanceEstimateValidator {
        var rules: [any RollingRemittanceEstimateRule]

        init(rules: [any RollingRemittanceEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingRemittanceEstimate) -> [String] {
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

        func requireValid(_ item: RollingRemittanceEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingRemittanceEstimate]) -> [String: [String]] {
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

    static func defaultRollingRemittanceEstimateValidator() -> RollingRemittanceEstimateValidator {
        return RollingRemittanceEstimateValidator(
            rules: [
                RollingRemittanceEstimateLabelLengthRule(maxLength: 80),
                RollingRemittanceEstimateRequiredCurrencyRule(message: "rolling remittance estimate needs this field"),
                RollingRemittanceEstimateAllowedPatientRefRule(allowed: ["manual"]),
                RollingRemittanceEstimateRequiredPatientRefRule(message: "rolling remittance estimate needs a value"),
                RollingRemittanceEstimateCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
