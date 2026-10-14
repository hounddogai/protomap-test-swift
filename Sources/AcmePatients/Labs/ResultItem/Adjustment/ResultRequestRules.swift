import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result request must pass. Check returns its problems, or none.
    protocol ResultRequestRule {
        func check(_ item: ResultRequest) -> [String]
    }

    final class ResultRequestCreatedAtRangeRule: ResultRequestRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultRequest) -> [String] {
            let value = item.createdAt
            var problems: [String] = []
            if value < min {
                problems.append("created at \(value) is below \(min)")
            }
            if value > max {
                problems.append("created at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ResultRequestAllowedCodeRule: ResultRequestRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ResultRequest) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is expired"]
            }
            return []
        }
    }

    final class ResultRequestAmountRangeRule: ResultRequestRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultRequest) -> [String] {
            let value = item.amount
            if value < min || value > max {
                return ["amount \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ResultRequestTitleLengthRule: ResultRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultRequest) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultRequestRequiredCodeRule: ResultRequestRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultRequest) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultRequestCodeLengthRule: ResultRequestRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultRequest) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result request.
    final class ResultRequestValidator {
        var rules: [any ResultRequestRule]

        init(rules: [any ResultRequestRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultRequest) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultRequest) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultRequest]) -> [String: [String]] {
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

    static func defaultResultRequestValidator() -> ResultRequestValidator {
        return ResultRequestValidator(
            rules: [
                ResultRequestCreatedAtRangeRule(min: 1000, max: 3600),
                ResultRequestAllowedCodeRule(allowed: ["legacy", "scheduled", "manual"]),
                ResultRequestAmountRangeRule(min: 8.5, max: 1478.8),
                ResultRequestTitleLengthRule(maxLength: 1000),
                ResultRequestRequiredCodeRule(message: "result request needs a value"),
                ResultRequestCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
