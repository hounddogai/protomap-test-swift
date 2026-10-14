import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a care gap variance must pass. Check returns its problems, or none.
    protocol CareGapVarianceRule {
        func check(_ item: CareGapVariance) -> [String]
    }

    final class CareGapVarianceSourceLengthRule: CareGapVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareGapVariance) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareGapVarianceRequiredSpecialtyRule: CareGapVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareGapVariance) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareGapVarianceBudgetRangeRule: CareGapVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareGapVariance) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a care gap variance.
    final class CareGapVarianceValidator {
        var rules: [any CareGapVarianceRule]

        init(rules: [any CareGapVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: CareGapVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareGapVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareGapVariance]) -> [String: [String]] {
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

    static func defaultCareGapVarianceValidator() -> CareGapVarianceValidator {
        return CareGapVarianceValidator(
            rules: [
                CareGapVarianceSourceLengthRule(maxLength: 255),
                CareGapVarianceRequiredSpecialtyRule(message: "care gap variance needs an entry"),
                CareGapVarianceBudgetRangeRule(min: 9.6, max: 2763.1),
            ]
        )
    }
}
