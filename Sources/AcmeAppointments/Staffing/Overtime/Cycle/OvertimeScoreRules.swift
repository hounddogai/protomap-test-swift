import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a overtime score must pass. Check returns its problems, or none.
    protocol OvertimeScoreRule {
        func check(_ item: OvertimeScore) -> [String]
    }

    final class OvertimeScoreWeightRangeRule: OvertimeScoreRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: OvertimeScore) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class OvertimeScoreCurrencyLengthRule: OvertimeScoreRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: OvertimeScore) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class OvertimeScoreRequiredTitleRule: OvertimeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeScore) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class OvertimeScoreRequiredCodeRule: OvertimeScoreRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: OvertimeScore) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a overtime score.
    final class OvertimeScoreValidator {
        var rules: [any OvertimeScoreRule]

        init(rules: [any OvertimeScoreRule]) {
            self.rules = rules
        }

        func validate(_ item: OvertimeScore) -> [String] {
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

        func requireValid(_ item: OvertimeScore) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [OvertimeScore]) -> [String: [String]] {
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

    static func defaultOvertimeScoreValidator() -> OvertimeScoreValidator {
        return OvertimeScoreValidator(
            rules: [
                OvertimeScoreWeightRangeRule(min: 8.5, max: 860.8),
                OvertimeScoreCurrencyLengthRule(maxLength: 80),
                OvertimeScoreRequiredTitleRule(message: "overtime score needs an entry"),
                OvertimeScoreRequiredCodeRule(message: "overtime score needs a value"),
            ]
        )
    }
}
