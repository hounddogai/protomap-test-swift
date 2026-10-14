import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier estimate must pass. Check returns its problems, or none.
    protocol CourierEstimateRule {
        func check(_ item: CourierEstimate) -> [String]
    }

    final class CourierEstimateRequiredCodeRule: CourierEstimateRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierEstimate) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierEstimateCodeLengthRule: CourierEstimateRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierEstimate) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CourierEstimateRefillsRangeRule: CourierEstimateRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CourierEstimate) -> [String] {
            let value = item.refills
            if value < min || value > max {
                return ["refills \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier estimate.
    final class CourierEstimateValidator {
        var rules: [any CourierEstimateRule]

        init(rules: [any CourierEstimateRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierEstimate) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierEstimate) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierEstimate]) -> [String: [String]] {
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

    static func defaultCourierEstimateValidator() -> CourierEstimateValidator {
        return CourierEstimateValidator(
            rules: [
                CourierEstimateRequiredCodeRule(message: "courier estimate needs a value"),
                CourierEstimateCodeLengthRule(maxLength: 32),
                CourierEstimateRefillsRangeRule(min: 32, max: 255),
            ]
        )
    }
}
