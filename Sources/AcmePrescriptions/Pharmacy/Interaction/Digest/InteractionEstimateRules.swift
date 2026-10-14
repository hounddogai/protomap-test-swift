import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction estimate must pass. Check returns its problems, or none.
    protocol InteractionEstimateRule {
        func check(_ item: InteractionEstimate) -> [String]
    }

    final class InteractionEstimateBedLengthRule: InteractionEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionEstimate) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionEstimateRequiredCodeRule: InteractionEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionEstimateUpdatedAtRangeRule: InteractionEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionEstimate) -> [String] {
            let value = item.updatedAt
            if value < min || value > max {
                return ["updated at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a interaction estimate.
    final class InteractionEstimateValidator {
        var rules: [any InteractionEstimateRule]

        init(rules: [any InteractionEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: InteractionEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionEstimate]) -> [String: [String]] {
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

    static func defaultInteractionEstimateValidator() -> InteractionEstimateValidator {
        return InteractionEstimateValidator(
            rules: [
                InteractionEstimateBedLengthRule(maxLength: 1000),
                InteractionEstimateRequiredCodeRule(message: "interaction estimate needs an entry"),
                InteractionEstimateUpdatedAtRangeRule(min: 16, max: 1000),
            ]
        )
    }
}
