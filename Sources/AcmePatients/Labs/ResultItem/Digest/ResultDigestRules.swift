import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result digest must pass. Check returns its problems, or none.
    protocol ResultDigestRule {
        func check(_ item: ResultDigest) -> [String]
    }

    final class ResultDigestBudgetRangeRule: ResultDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultDigest) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultDigestRequiredCodeRule: ResultDigestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultDigest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultDigestCodeLengthRule: ResultDigestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultDigest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultDigestRatioRangeRule: ResultDigestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultDigest) -> [String] {
            let value = item.ratio
            if value < min || value > max {
                return ["ratio \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a result digest.
    final class ResultDigestValidator {
        var rules: [any ResultDigestRule]

        init(rules: [any ResultDigestRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultDigest) -> [String] {
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

        func requireValid(_ item: ResultDigest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultDigest]) -> [String: [String]] {
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

    static func defaultResultDigestValidator() -> ResultDigestValidator {
        return ResultDigestValidator(
            rules: [
                ResultDigestBudgetRangeRule(min: 1.2, max: 517.6),
                ResultDigestRequiredCodeRule(message: "result digest needs this field"),
                ResultDigestCodeLengthRule(maxLength: 16),
                ResultDigestRatioRangeRule(min: 5.3, max: 554.5),
            ]
        )
    }
}
