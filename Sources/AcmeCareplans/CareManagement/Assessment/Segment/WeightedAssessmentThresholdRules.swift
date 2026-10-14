import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a weighted assessment threshold must pass. Check returns its problems, or none.
    protocol WeightedAssessmentThresholdRule {
        func check(_ item: WeightedAssessmentThreshold) -> [String]
    }

    final class WeightedAssessmentThresholdCodeLengthRule: WeightedAssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAssessmentThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAssessmentThresholdFacilityLengthRule: WeightedAssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedAssessmentThreshold) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedAssessmentThresholdRateRangeRule: WeightedAssessmentThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedAssessmentThreshold) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedAssessmentThresholdRequiredLabelRule: WeightedAssessmentThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedAssessmentThreshold) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted assessment threshold.
    final class WeightedAssessmentThresholdValidator {
        var rules: [any WeightedAssessmentThresholdRule]

        init(rules: [any WeightedAssessmentThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedAssessmentThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: WeightedAssessmentThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedAssessmentThreshold]) -> [String: [String]] {
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

    static func defaultWeightedAssessmentThresholdValidator() -> WeightedAssessmentThresholdValidator {
        return WeightedAssessmentThresholdValidator(
            rules: [
                WeightedAssessmentThresholdCodeLengthRule(maxLength: 16),
                WeightedAssessmentThresholdFacilityLengthRule(maxLength: 120),
                WeightedAssessmentThresholdRateRangeRule(min: 8.7, max: 1833.4),
                WeightedAssessmentThresholdRequiredLabelRule(
                    message: "weighted assessment threshold needs this field"
                ),
            ]
        )
    }
}
