import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier summary must pass. Check returns its problems, or none.
    protocol CourierSummaryRule {
        func check(_ item: CourierSummary) -> [String]
    }

    final class CourierSummaryRequiredCodeRule: CourierSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierSummary) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierSummaryTimezoneLengthRule: CourierSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierSummary) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierSummaryRequiredNameRule: CourierSummaryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierSummary) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierSummaryThresholdRangeRule: CourierSummaryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierSummary) -> [String] {
            let value = item.threshold
            var problems: [String] = []
            if value < min {
                problems.append("threshold \(value) is below \(min)")
            }
            if value > max {
                problems.append("threshold \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CourierSummaryNameLengthRule: CourierSummaryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierSummary) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier summary.
    final class CourierSummaryValidator {
        var rules: [any CourierSummaryRule]

        init(rules: [any CourierSummaryRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierSummary) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierSummary) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierSummary]) -> [String: [String]] {
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

    static func defaultCourierSummaryValidator() -> CourierSummaryValidator {
        return CourierSummaryValidator(
            rules: [
                CourierSummaryRequiredCodeRule(message: "courier summary needs this field"),
                CourierSummaryTimezoneLengthRule(maxLength: 16),
                CourierSummaryRequiredNameRule(message: "courier summary needs a value"),
                CourierSummaryThresholdRangeRule(min: 3.9, max: 4373.0),
                CourierSummaryNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
