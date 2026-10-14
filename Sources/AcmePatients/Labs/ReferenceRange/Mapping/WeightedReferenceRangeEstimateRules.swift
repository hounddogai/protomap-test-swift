import AcmePlatform
import Foundation

extension Labs {
    /// A rule a weighted reference range estimate must pass. Check returns its problems, or none.
    protocol WeightedReferenceRangeEstimateRule {
        func check(_ item: WeightedReferenceRangeEstimate) -> [String]
    }

    final class WeightedReferenceRangeEstimateMaximumRangeRule: WeightedReferenceRangeEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferenceRangeEstimate) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class WeightedReferenceRangeEstimateTitleLengthRule: WeightedReferenceRangeEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedReferenceRangeEstimate) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedReferenceRangeEstimateRequiredCodeRule: WeightedReferenceRangeEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedReferenceRangeEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class WeightedReferenceRangeEstimateDurationMinutesRangeRule: WeightedReferenceRangeEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferenceRangeEstimate) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedReferenceRangeEstimateDiscountRangeRule: WeightedReferenceRangeEstimateRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedReferenceRangeEstimate) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a weighted reference range estimate.
    final class WeightedReferenceRangeEstimateValidator {
        var rules: [any WeightedReferenceRangeEstimateRule]

        init(rules: [any WeightedReferenceRangeEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedReferenceRangeEstimate) -> [String] {
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

        func requireValid(_ item: WeightedReferenceRangeEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedReferenceRangeEstimate]) -> [String: [String]] {
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

    static func defaultWeightedReferenceRangeEstimateValidator() -> WeightedReferenceRangeEstimateValidator {
        return WeightedReferenceRangeEstimateValidator(
            rules: [
                WeightedReferenceRangeEstimateMaximumRangeRule(min: 2.1, max: 2574.9),
                WeightedReferenceRangeEstimateTitleLengthRule(maxLength: 80),
                WeightedReferenceRangeEstimateRequiredCodeRule(
                    message: "weighted reference range estimate needs this field"
                ),
                WeightedReferenceRangeEstimateDurationMinutesRangeRule(min: 80, max: 255),
                WeightedReferenceRangeEstimateDiscountRangeRule(min: 9.2, max: 3208.3),
            ]
        )
    }
}
