import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score digest must pass. Check returns its problems, or none.
    protocol RiskScoreDigestRule {
        func check(_ item: RiskScoreDigest) -> [String]
    }

    final class RiskScoreDigestThresholdRangeRule: RiskScoreDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreDigest) -> [String] {
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

    final class RiskScoreDigestLocaleLengthRule: RiskScoreDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreDigest) -> [String] {
            let size = item.locale.count
            if size > maxLength {
                return ["locale is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreDigestAllowedLabelRule: RiskScoreDigestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RiskScoreDigest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.label)) {
                return ["label \(item.label) is missing"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score digest.
    final class RiskScoreDigestValidator {
        var rules: [any RiskScoreDigestRule]

        init(rules: [any RiskScoreDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreDigest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreDigest]) -> [String: [String]] {
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

    static func defaultRiskScoreDigestValidator() -> RiskScoreDigestValidator {
        return RiskScoreDigestValidator(
            rules: [
                RiskScoreDigestThresholdRangeRule(min: 1.4, max: 4047.1),
                RiskScoreDigestLocaleLengthRule(maxLength: 255),
                RiskScoreDigestAllowedLabelRule(allowed: []),
            ]
        )
    }
}
