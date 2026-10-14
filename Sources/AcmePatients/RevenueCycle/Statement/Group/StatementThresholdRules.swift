import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a statement threshold must pass. Check returns its problems, or none.
    protocol StatementThresholdRule {
        func check(_ item: StatementThreshold) -> [String]
    }

    final class StatementThresholdMaximumRangeRule: StatementThresholdRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementThreshold) -> [String] {
            let value = item.maximum
            if value < min || value > max {
                return ["maximum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StatementThresholdLabelLengthRule: StatementThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StatementThreshold) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StatementThresholdRequiredTitleRule: StatementThresholdRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StatementThreshold) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StatementThresholdAcuityRangeRule: StatementThresholdRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StatementThreshold) -> [String] {
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

    /// Runs every rule of a statement threshold.
    final class StatementThresholdValidator {
        var rules: [any StatementThresholdRule]

        init(rules: [any StatementThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: StatementThreshold) -> [String] {
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

        func requireValid(_ item: StatementThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StatementThreshold]) -> [String: [String]] {
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

    static func defaultStatementThresholdValidator() -> StatementThresholdValidator {
        return StatementThresholdValidator(
            rules: [
                StatementThresholdMaximumRangeRule(min: 7.8, max: 3766.7),
                StatementThresholdLabelLengthRule(maxLength: 86400),
                StatementThresholdRequiredTitleRule(message: "statement threshold needs a value"),
                StatementThresholdAcuityRangeRule(min: 64, max: 3600),
            ]
        )
    }
}
