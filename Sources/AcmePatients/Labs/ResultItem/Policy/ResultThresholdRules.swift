import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result threshold must pass. Check returns its problems, or none.
    protocol ResultThresholdRule {
        func check(_ item: ResultThreshold) -> [String]
    }

    final class ResultThresholdProcedureCodeLengthRule: ResultThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultThreshold) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultThresholdCodePrefixRule: ResultThresholdRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultThreshold) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ResultThresholdCodeLengthRule: ResultThresholdRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultThreshold) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a result threshold.
    final class ResultThresholdValidator {
        var rules: [any ResultThresholdRule]

        init(rules: [any ResultThresholdRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultThreshold) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultThreshold) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultThreshold]) -> [String: [String]] {
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

    static func defaultResultThresholdValidator() -> ResultThresholdValidator {
        return ResultThresholdValidator(
            rules: [
                ResultThresholdProcedureCodeLengthRule(maxLength: 120),
                ResultThresholdCodePrefixRule(prefix: "Q"),
                ResultThresholdCodeLengthRule(maxLength: 32),
            ]
        )
    }
}
