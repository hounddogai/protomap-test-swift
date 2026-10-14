import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set variance must pass. Check returns its problems, or none.
    protocol OrderSetVarianceRule {
        func check(_ item: OrderSetVariance) -> [String]
    }

    final class OrderSetVarianceRequiredLabelRule: OrderSetVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetVariance) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetVarianceAcuityRangeRule: OrderSetVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetVariance) -> [String] {
            let value = item.acuity
            var problems: [String] = []
            if value < min {
                problems.append("acuity \(value) is below \(min)")
            }
            if value > max {
                problems.append("acuity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OrderSetVarianceCodeLengthRule: OrderSetVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetVarianceScoreRangeRule: OrderSetVarianceRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetVariance) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class OrderSetVarianceEndsAtRangeRule: OrderSetVarianceRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetVariance) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set variance.
    final class OrderSetVarianceValidator {
        var rules: [any OrderSetVarianceRule]

        init(rules: [any OrderSetVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetVariance]) -> [String: [String]] {
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

    static func defaultOrderSetVarianceValidator() -> OrderSetVarianceValidator {
        return OrderSetVarianceValidator(
            rules: [
                OrderSetVarianceRequiredLabelRule(message: "order set variance needs this field"),
                OrderSetVarianceAcuityRangeRule(min: 16, max: 3600),
                OrderSetVarianceCodeLengthRule(maxLength: 16),
                OrderSetVarianceScoreRangeRule(min: 6.5, max: 532.6),
                OrderSetVarianceEndsAtRangeRule(min: 1000, max: 3600),
            ]
        )
    }
}
