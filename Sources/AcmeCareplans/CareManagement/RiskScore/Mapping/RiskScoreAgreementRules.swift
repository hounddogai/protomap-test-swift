import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score agreement must pass. Check returns its problems, or none.
    protocol RiskScoreAgreementRule {
        func check(_ item: RiskScoreAgreement) -> [String]
    }

    final class RiskScoreAgreementThresholdRangeRule: RiskScoreAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreAgreement) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RiskScoreAgreementAllowedRegionRule: RiskScoreAgreementRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreAgreement) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.region)) {
                return ["region \(item.region) is too long"]
            }
            return []
        }
    }

    final class RiskScoreAgreementCopayRangeRule: RiskScoreAgreementRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreAgreement) -> [String] {
            let value = item.copay
            if value < min || value > max {
                return ["copay \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score agreement.
    final class RiskScoreAgreementValidator {
        var rules: [any RiskScoreAgreementRule]

        init(rules: [any RiskScoreAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreAgreement) -> [String] {
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

        func requireValid(_ item: RiskScoreAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreAgreement]) -> [String: [String]] {
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

    static func defaultRiskScoreAgreementValidator() -> RiskScoreAgreementValidator {
        return RiskScoreAgreementValidator(
            rules: [
                RiskScoreAgreementThresholdRangeRule(min: 2.2, max: 1885.6),
                RiskScoreAgreementAllowedRegionRule(allowed: ["legacy"]),
                RiskScoreAgreementCopayRangeRule(min: 1.7, max: 4501.1),
            ]
        )
    }
}
