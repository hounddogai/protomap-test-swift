import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a assessment variance must pass. Check returns its problems, or none.
    protocol AssessmentVarianceRule {
        func check(_ item: AssessmentVariance) -> [String]
    }

    final class AssessmentVarianceRefillsRangeRule: AssessmentVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentVariance) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class AssessmentVarianceAttemptsRangeRule: AssessmentVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentVariance) -> [String] {
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

    final class AssessmentVarianceTitleLengthRule: AssessmentVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: AssessmentVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class AssessmentVarianceGraceDaysRangeRule: AssessmentVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AssessmentVariance) -> [String] {
            let value = item.graceDays
            var problems: [String] = []
            if value < min {
                problems.append("grace days \(value) is below \(min)")
            }
            if value > max {
                problems.append("grace days \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a assessment variance.
    final class AssessmentVarianceValidator {
        var rules: [any AssessmentVarianceRule]

        init(rules: [any AssessmentVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: AssessmentVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: AssessmentVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AssessmentVariance]) -> [String: [String]] {
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

    static func defaultAssessmentVarianceValidator() -> AssessmentVarianceValidator {
        return AssessmentVarianceValidator(
            rules: [
                AssessmentVarianceRefillsRangeRule(min: 80, max: 120),
                AssessmentVarianceAttemptsRangeRule(min: 16, max: 80),
                AssessmentVarianceTitleLengthRule(maxLength: 16),
                AssessmentVarianceGraceDaysRangeRule(min: 32, max: 64),
            ]
        )
    }
}
