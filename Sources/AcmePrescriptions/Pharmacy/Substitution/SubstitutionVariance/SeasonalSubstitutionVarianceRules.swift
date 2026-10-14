import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a seasonal substitution variance must pass. Check returns its problems, or none.
    protocol SeasonalSubstitutionVarianceRule {
        func check(_ item: SeasonalSubstitutionVariance) -> [String]
    }

    final class SeasonalSubstitutionVarianceNameLengthRule: SeasonalSubstitutionVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: SeasonalSubstitutionVariance) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class SeasonalSubstitutionVarianceCapacityRangeRule: SeasonalSubstitutionVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: SeasonalSubstitutionVariance) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class SeasonalSubstitutionVarianceRequiredCodeRule: SeasonalSubstitutionVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: SeasonalSubstitutionVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a seasonal substitution variance.
    final class SeasonalSubstitutionVarianceValidator {
        var rules: [any SeasonalSubstitutionVarianceRule]

        init(rules: [any SeasonalSubstitutionVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: SeasonalSubstitutionVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: SeasonalSubstitutionVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [SeasonalSubstitutionVariance]) -> [String: [String]] {
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

    static func defaultSeasonalSubstitutionVarianceValidator() -> SeasonalSubstitutionVarianceValidator {
        return SeasonalSubstitutionVarianceValidator(
            rules: [
                SeasonalSubstitutionVarianceNameLengthRule(maxLength: 64),
                SeasonalSubstitutionVarianceCapacityRangeRule(min: 16, max: 80),
                SeasonalSubstitutionVarianceRequiredCodeRule(message: "seasonal substitution variance needs an entry"),
            ]
        )
    }
}
