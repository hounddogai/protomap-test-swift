import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment threshold must pass. Check returns its problems, or none.
    protocol AssessmentThresholdRule {
        func check(_ item: AssessmentThreshold) -> [String]
    }

    final class AssessmentThresholdSpecialtyLengthRule: AssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentThreshold) -> [String] {
            let size = item.specialty.count
            if size > maxLength {
                return ["specialty is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentThresholdRateRangeRule: AssessmentThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentThreshold) -> [String] {
            let value = item.rate
            if value < min || value > max {
                return ["rate \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentThresholdDosageMgRangeRule: AssessmentThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentThreshold) -> [String] {
            let value = item.dosageMg
            var problems: [String] = []
            if value < min {
                problems.append("dosage mg \(value) is below \(min)")
            }
            if value > max {
                problems.append("dosage mg \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AssessmentThresholdAllergyLengthRule: AssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentThreshold) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentThresholdCodeLengthRule: AssessmentThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a assessment threshold.
    final class AssessmentThresholdValidator {
        var rules: [any AssessmentThresholdRule]

        init(rules: [any AssessmentThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentThreshold]) -> [String: [String]] {
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

    static func defaultAssessmentThresholdValidator() -> AssessmentThresholdValidator {
        return AssessmentThresholdValidator(
            rules: [
                AssessmentThresholdSpecialtyLengthRule(maxLength: 16),
                AssessmentThresholdRateRangeRule(min: 7.6, max: 2790.6),
                AssessmentThresholdDosageMgRangeRule(min: 4.6, max: 4921.3),
                AssessmentThresholdAllergyLengthRule(maxLength: 1000),
                AssessmentThresholdCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
