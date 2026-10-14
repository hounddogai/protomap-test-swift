import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result policy must pass. Check returns its problems, or none.
    protocol ResultPolicyRule {
        func check(_ item: ResultPolicy) -> [String]
    }

    final class ResultPolicyRequiredCodeRule: ResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultPolicy) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultPolicyCodeLengthRule: ResultPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultPolicy) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultPolicyRequiredContactEmailRule: ResultPolicyRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultPolicy) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultPolicySequenceRangeRule: ResultPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultPolicy) -> [String] {
            let value = item.sequence
            var problems: [String] = []
            if value < min {
                problems.append("sequence \(value) is below \(min)")
            }
            if value > max {
                problems.append("sequence \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a result policy.
    final class ResultPolicyValidator {
        var rules: [any ResultPolicyRule]

        init(rules: [any ResultPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultPolicy) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultPolicy]) -> [String: [String]] {
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

    static func defaultResultPolicyValidator() -> ResultPolicyValidator {
        return ResultPolicyValidator(
            rules: [
                ResultPolicyRequiredCodeRule(message: "result policy needs a value"),
                ResultPolicyCodeLengthRule(maxLength: 3600),
                ResultPolicyRequiredContactEmailRule(message: "result policy needs a value"),
                ResultPolicySequenceRangeRule(min: 120, max: 255),
            ]
        )
    }
}
