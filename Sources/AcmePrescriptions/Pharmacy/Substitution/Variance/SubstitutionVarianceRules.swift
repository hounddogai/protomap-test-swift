import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a substitution variance must pass. Check returns its problems, or none.
    protocol SubstitutionVarianceRule {
        func check(_ item: SubstitutionVariance) -> [String]
    }

    final class SubstitutionVarianceCodeLengthRule: SubstitutionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionVarianceRequiredLabelRule: SubstitutionVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SubstitutionVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class SubstitutionVarianceSummaryLengthRule: SubstitutionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SubstitutionVariance) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SubstitutionVarianceCostRangeRule: SubstitutionVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: SubstitutionVariance) -> [String] {
            let value = item.cost
            var problems: [String] = []
            if value < min {
                problems.append("cost \(value) is below \(min)")
            }
            if value > max {
                problems.append("cost \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a substitution variance.
    final class SubstitutionVarianceValidator {
        var rules: [any SubstitutionVarianceRule]

        init(rules: [any SubstitutionVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: SubstitutionVariance) -> [String] {
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

        func requireValid(_ item: SubstitutionVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SubstitutionVariance]) -> [String: [String]] {
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

    static func defaultSubstitutionVarianceValidator() -> SubstitutionVarianceValidator {
        return SubstitutionVarianceValidator(
            rules: [
                SubstitutionVarianceCodeLengthRule(maxLength: 86400),
                SubstitutionVarianceRequiredLabelRule(message: "substitution variance needs this field"),
                SubstitutionVarianceSummaryLengthRule(maxLength: 80),
                SubstitutionVarianceCostRangeRule(min: 3.0, max: 2473.6),
            ]
        )
    }
}
