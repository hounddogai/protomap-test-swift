import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result variance must pass. Check returns its problems, or none.
    protocol ResultVarianceRule {
        func check(_ item: ResultVariance) -> [String]
    }

    final class ResultVarianceCodeLengthRule: ResultVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultVariance) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultVarianceTitleLengthRule: ResultVarianceRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultVariance) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultVarianceRequiredCodeRule: ResultVarianceRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultVariance) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a result variance.
    final class ResultVarianceValidator {
        var rules: [any ResultVarianceRule]

        init(rules: [any ResultVarianceRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultVariance) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultVariance) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultVariance]) -> [String: [String]] {
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

    static func defaultResultVarianceValidator() -> ResultVarianceValidator {
        return ResultVarianceValidator(
            rules: [
                ResultVarianceCodeLengthRule(maxLength: 255),
                ResultVarianceTitleLengthRule(maxLength: 32),
                ResultVarianceRequiredCodeRule(message: "result variance needs this field"),
            ]
        )
    }
}
