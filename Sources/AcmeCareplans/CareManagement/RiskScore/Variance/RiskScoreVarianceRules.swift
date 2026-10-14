import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a risk score variance must pass. Check returns its problems, or none.
    protocol RiskScoreVarianceRule {
        func check(_ item: RiskScoreVariance) -> [String]
    }

    final class RiskScoreVarianceSegmentLengthRule: RiskScoreVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreVariance) -> [String] {
            let size = item.segment.count
            if size > maxLength {
                return ["segment is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RiskScoreVarianceRequiredCodeRule: RiskScoreVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreVarianceRequiredSegmentRule: RiskScoreVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RiskScoreVariance) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RiskScoreVarianceThresholdRangeRule: RiskScoreVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RiskScoreVariance) -> [String] {
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

    final class RiskScoreVarianceExternalRefLengthRule: RiskScoreVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RiskScoreVariance) -> [String] {
            let size = item.externalRef.count
            if size > maxLength {
                return ["external ref is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a risk score variance.
    final class RiskScoreVarianceValidator {
        var rules: [any RiskScoreVarianceRule]

        init(rules: [any RiskScoreVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: RiskScoreVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RiskScoreVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RiskScoreVariance]) -> [String: [String]] {
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

    static func defaultRiskScoreVarianceValidator() -> RiskScoreVarianceValidator {
        return RiskScoreVarianceValidator(
            rules: [
                RiskScoreVarianceSegmentLengthRule(maxLength: 64),
                RiskScoreVarianceRequiredCodeRule(message: "risk score variance needs an entry"),
                RiskScoreVarianceRequiredSegmentRule(message: "risk score variance needs this field"),
                RiskScoreVarianceThresholdRangeRule(min: 9.1, max: 4195.7),
                RiskScoreVarianceExternalRefLengthRule(maxLength: 64),
            ]
        )
    }
}
