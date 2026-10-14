import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a weighted worklist template must pass. Check returns its problems, or none.
    protocol WeightedWorklistTemplateRule {
        func check(_ item: WeightedWorklistTemplate) -> [String]
    }

    final class WeightedWorklistTemplateRequiredCountryRule: WeightedWorklistTemplateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedWorklistTemplate) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedWorklistTemplateCountryLengthRule: WeightedWorklistTemplateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedWorklistTemplate) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedWorklistTemplateUpdatedAtRangeRule: WeightedWorklistTemplateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedWorklistTemplate) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a weighted worklist template.
    final class WeightedWorklistTemplateValidator {
        var rules: [any WeightedWorklistTemplateRule]

        init(rules: [any WeightedWorklistTemplateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedWorklistTemplate) -> [String] {
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

        func requireValid(_ item: WeightedWorklistTemplate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedWorklistTemplate]) -> [String: [String]] {
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

    static func defaultWeightedWorklistTemplateValidator() -> WeightedWorklistTemplateValidator {
        return WeightedWorklistTemplateValidator(
            rules: [
                WeightedWorklistTemplateRequiredCountryRule(message: "weighted worklist template needs an entry"),
                WeightedWorklistTemplateCountryLengthRule(maxLength: 3600),
                WeightedWorklistTemplateUpdatedAtRangeRule(min: 32, max: 255),
            ]
        )
    }
}
