import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a order set threshold must pass. Check returns its problems, or none.
    protocol OrderSetThresholdRule {
        func check(_ item: OrderSetThreshold) -> [String]
    }

    final class OrderSetThresholdReviewerLengthRule: OrderSetThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetThreshold) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetThresholdTitleLengthRule: OrderSetThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetThreshold) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetThresholdRequiredReviewerRule: OrderSetThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OrderSetThreshold) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OrderSetThresholdCodeLengthRule: OrderSetThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OrderSetThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OrderSetThresholdPriorityRangeRule: OrderSetThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: OrderSetThreshold) -> [String] {
            let value = item.priority
            if value < min || value > max {
                return ["priority \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a order set threshold.
    final class OrderSetThresholdValidator {
        var rules: [any OrderSetThresholdRule]

        init(rules: [any OrderSetThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: OrderSetThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: OrderSetThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OrderSetThreshold]) -> [String: [String]] {
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

    static func defaultOrderSetThresholdValidator() -> OrderSetThresholdValidator {
        return OrderSetThresholdValidator(
            rules: [
                OrderSetThresholdReviewerLengthRule(maxLength: 86400),
                OrderSetThresholdTitleLengthRule(maxLength: 120),
                OrderSetThresholdRequiredReviewerRule(message: "order set threshold needs a value"),
                OrderSetThresholdCodeLengthRule(maxLength: 3600),
                OrderSetThresholdPriorityRangeRule(min: 32, max: 86400),
            ]
        )
    }
}
