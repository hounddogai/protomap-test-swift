import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result metric must pass. Check returns its problems, or none.
    protocol ResultMetricRule {
        func check(_ item: ResultMetric) -> [String]
    }

    final class ResultMetricAttemptsRangeRule: ResultMetricRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultMetric) -> [String] {
            let value = item.attempts
            if value < min || value > max {
                return ["attempts \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultMetricChecksumLengthRule: ResultMetricRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultMetric) -> [String] {
            let size = item.checksum.count
            if size > maxLength {
                return ["checksum is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultMetricRequiredCodeRule: ResultMetricRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultMetric) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result metric.
    final class ResultMetricValidator {
        var rules: [any ResultMetricRule]

        init(rules: [any ResultMetricRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultMetric) -> [String] {
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

        func requireValid(_ item: ResultMetric) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultMetric]) -> [String: [String]] {
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

    static func defaultResultMetricValidator() -> ResultMetricValidator {
        return ResultMetricValidator(
            rules: [
                ResultMetricAttemptsRangeRule(min: 80, max: 3600),
                ResultMetricChecksumLengthRule(maxLength: 3600),
                ResultMetricRequiredCodeRule(message: "result metric needs a value"),
            ]
        )
    }
}
