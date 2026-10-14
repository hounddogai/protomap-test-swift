import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a primary authorization metric must pass. Check returns its problems, or none.
    protocol PrimaryAuthorizationMetricRule {
        func check(_ item: PrimaryAuthorizationMetric) -> [String]
    }

    final class PrimaryAuthorizationMetricCodeLengthRule: PrimaryAuthorizationMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAuthorizationMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAuthorizationMetricRequiredCodeRule: PrimaryAuthorizationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAuthorizationMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAuthorizationMetricRequiredReviewerRule: PrimaryAuthorizationMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryAuthorizationMetric) -> [String] {
            if item.reviewer.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryAuthorizationMetricLabelLengthRule: PrimaryAuthorizationMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryAuthorizationMetric) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryAuthorizationMetricBatchSizeRangeRule: PrimaryAuthorizationMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryAuthorizationMetric) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a primary authorization metric.
    final class PrimaryAuthorizationMetricValidator {
        var rules: [any PrimaryAuthorizationMetricRule]

        init(rules: [any PrimaryAuthorizationMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryAuthorizationMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryAuthorizationMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryAuthorizationMetric]) -> [String: [String]] {
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

    static func defaultPrimaryAuthorizationMetricValidator() -> PrimaryAuthorizationMetricValidator {
        return PrimaryAuthorizationMetricValidator(
            rules: [
                PrimaryAuthorizationMetricCodeLengthRule(maxLength: 80),
                PrimaryAuthorizationMetricRequiredCodeRule(message: "primary authorization metric needs an entry"),
                PrimaryAuthorizationMetricRequiredReviewerRule(
                    message: "primary authorization metric needs this field"
                ),
                PrimaryAuthorizationMetricLabelLengthRule(maxLength: 120),
                PrimaryAuthorizationMetricBatchSizeRangeRule(min: 16, max: 80),
            ]
        )
    }
}
