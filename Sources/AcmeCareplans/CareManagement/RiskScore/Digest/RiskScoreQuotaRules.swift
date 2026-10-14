import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score quota must pass. Check returns its problems, or none.
    protocol RiskScoreQuotaRule {
        func check(_ item: RiskScoreQuota) -> [String]
    }

    final class RiskScoreQuotaRequiredPatientRefRule: RiskScoreQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreQuota) -> [String] {
            if item.patientRef.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreQuotaCodePrefixRule: RiskScoreQuotaRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RiskScoreQuota) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RiskScoreQuotaDiscountRangeRule: RiskScoreQuotaRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreQuota) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreQuotaPatientRefLengthRule: RiskScoreQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreQuota) -> [String] {
            let size = item.patientRef.count
            if size > maxLength {
                return ["patient ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score quota.
    final class RiskScoreQuotaValidator {
        var rules: [any RiskScoreQuotaRule]

        init(rules: [any RiskScoreQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreQuota]) -> [String: [String]] {
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

    static func defaultRiskScoreQuotaValidator() -> RiskScoreQuotaValidator {
        return RiskScoreQuotaValidator(
            rules: [
                RiskScoreQuotaRequiredPatientRefRule(message: "risk score quota needs an entry"),
                RiskScoreQuotaCodePrefixRule(prefix: "Q"),
                RiskScoreQuotaDiscountRangeRule(min: 3.7, max: 4465.9),
                RiskScoreQuotaPatientRefLengthRule(maxLength: 32),
            ]
        )
    }
}
