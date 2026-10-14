import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a weighted interaction exception must pass. Check returns its problems, or none.
    protocol WeightedInteractionExceptionRule {
        func check(_ item: WeightedInteractionException) -> [String]
    }

    final class WeightedInteractionExceptionWeightRangeRule: WeightedInteractionExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInteractionException) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class WeightedInteractionExceptionRateRangeRule: WeightedInteractionExceptionRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: WeightedInteractionException) -> [String] {
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

    final class WeightedInteractionExceptionTitleLengthRule: WeightedInteractionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedInteractionException) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedInteractionExceptionCountryLengthRule: WeightedInteractionExceptionRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: WeightedInteractionException) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class WeightedInteractionExceptionRequiredTitleRule: WeightedInteractionExceptionRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: WeightedInteractionException) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a weighted interaction exception.
    final class WeightedInteractionExceptionValidator {
        var rules: [any WeightedInteractionExceptionRule]

        init(rules: [any WeightedInteractionExceptionRule]) {
            self.rules = rules
        }

        func validate(_ item: WeightedInteractionException) -> [String] {
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

        func requireValid(_ item: WeightedInteractionException) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [WeightedInteractionException]) -> [String: [String]] {
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

    static func defaultWeightedInteractionExceptionValidator() -> WeightedInteractionExceptionValidator {
        return WeightedInteractionExceptionValidator(
            rules: [
                WeightedInteractionExceptionWeightRangeRule(min: 0.3, max: 1220.5),
                WeightedInteractionExceptionRateRangeRule(min: 6.4, max: 4262.9),
                WeightedInteractionExceptionTitleLengthRule(maxLength: 3600),
                WeightedInteractionExceptionCountryLengthRule(maxLength: 32),
                WeightedInteractionExceptionRequiredTitleRule(
                    message: "weighted interaction exception needs this field"
                ),
            ]
        )
    }
}
