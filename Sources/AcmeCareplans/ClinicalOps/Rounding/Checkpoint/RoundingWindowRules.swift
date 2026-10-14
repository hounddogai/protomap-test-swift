import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a rounding window must pass. Check returns its problems, or none.
    protocol RoundingWindowRule {
        func check(_ item: RoundingWindow) -> [String]
    }

    final class RoundingWindowRequiredCodeRule: RoundingWindowRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RoundingWindow) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RoundingWindowThresholdRangeRule: RoundingWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingWindow) -> [String] {
            let value = item.threshold
            if value < min || value > max {
                return ["threshold \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class RoundingWindowCodeLengthRule: RoundingWindowRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RoundingWindow) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RoundingWindowCeilingRangeRule: RoundingWindowRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RoundingWindow) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a rounding window.
    final class RoundingWindowValidator {
        var rules: [any RoundingWindowRule]

        init(rules: [any RoundingWindowRule]) {
            self.rules = rules
        }

        func validate(_ item: RoundingWindow) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RoundingWindow) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RoundingWindow]) -> [String: [String]] {
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

    static func defaultRoundingWindowValidator() -> RoundingWindowValidator {
        return RoundingWindowValidator(
            rules: [
                RoundingWindowRequiredCodeRule(message: "rounding window needs a value"),
                RoundingWindowThresholdRangeRule(min: 1.8, max: 1805.3),
                RoundingWindowCodeLengthRule(maxLength: 32),
                RoundingWindowCeilingRangeRule(min: 6.3, max: 1537.8),
            ]
        )
    }
}
