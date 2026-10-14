import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a program metric must pass. Check returns its problems, or none.
    protocol ProgramMetricRule {
        func check(_ item: ProgramMetric) -> [String]
    }

    final class ProgramMetricCodeLengthRule: ProgramMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ProgramMetric) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ProgramMetricAllowedCodeRule: ProgramMetricRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ProgramMetric) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is inconsistent"]
            }
            return []
        }
    }

    final class ProgramMetricRequiredTitleRule: ProgramMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramMetric) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramMetricAttemptsRangeRule: ProgramMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramMetric) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ProgramMetricRequiredLocaleRule: ProgramMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ProgramMetric) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ProgramMetricDiscountRangeRule: ProgramMetricRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ProgramMetric) -> [String] {
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

    /// Runs every rule of a program metric.
    final class ProgramMetricValidator {
        var rules: [any ProgramMetricRule]

        init(rules: [any ProgramMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ProgramMetric) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ProgramMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ProgramMetric]) -> [String: [String]] {
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

    static func defaultProgramMetricValidator() -> ProgramMetricValidator {
        return ProgramMetricValidator(
            rules: [
                ProgramMetricCodeLengthRule(maxLength: 1000),
                ProgramMetricAllowedCodeRule(allowed: ["pending", "manual"]),
                ProgramMetricRequiredTitleRule(message: "program metric needs this field"),
                ProgramMetricAttemptsRangeRule(min: 32, max: 64),
                ProgramMetricRequiredLocaleRule(message: "program metric needs a value"),
                ProgramMetricDiscountRangeRule(min: 3.3, max: 2726.7),
            ]
        )
    }
}
