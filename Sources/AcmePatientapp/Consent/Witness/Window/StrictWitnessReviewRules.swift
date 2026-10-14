import AcmePlatform
import Foundation

extension Consent {
    /// A rule a strict witness review must pass. Check returns its problems, or none.
    protocol StrictWitnessReviewRule {
        func check(_ item: StrictWitnessReview) -> [String]
    }

    final class StrictWitnessReviewCapacityRangeRule: StrictWitnessReviewRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictWitnessReview) -> [String] {
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

    final class StrictWitnessReviewRequiredLabelRule: StrictWitnessReviewRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictWitnessReview) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictWitnessReviewCodePrefixRule: StrictWitnessReviewRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: StrictWitnessReview) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class StrictWitnessReviewLabelLengthRule: StrictWitnessReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWitnessReview) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictWitnessReviewCodeLengthRule: StrictWitnessReviewRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictWitnessReview) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict witness review.
    final class StrictWitnessReviewValidator {
        var rules: [any StrictWitnessReviewRule]

        init(rules: [any StrictWitnessReviewRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictWitnessReview) -> [String] {
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

        func requireValid(_ item: StrictWitnessReview) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictWitnessReview]) -> [String: [String]] {
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

    static func defaultStrictWitnessReviewValidator() -> StrictWitnessReviewValidator {
        return StrictWitnessReviewValidator(
            rules: [
                StrictWitnessReviewCapacityRangeRule(min: 80, max: 255),
                StrictWitnessReviewRequiredLabelRule(message: "strict witness review needs a value"),
                StrictWitnessReviewCodePrefixRule(prefix: "OPS"),
                StrictWitnessReviewLabelLengthRule(maxLength: 64),
                StrictWitnessReviewCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
