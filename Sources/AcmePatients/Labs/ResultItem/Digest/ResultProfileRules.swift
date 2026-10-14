import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result profile must pass. Check returns its problems, or none.
    protocol ResultProfileRule {
        func check(_ item: ResultProfile) -> [String]
    }

    final class ResultProfileChannelLengthRule: ResultProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultProfile) -> [String] {
            let size = item.channel.count
            if size > maxLength {
                return ["channel is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultProfileProcedureCodeLengthRule: ResultProfileRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultProfile) -> [String] {
            let size = item.procedureCode.count
            if size > maxLength {
                return ["procedure code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultProfileVersionRangeRule: ResultProfileRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ResultProfile) -> [String] {
            let value = item.version
            var problems: [String] = []
            if value < min {
                problems.append("version \(value) is below \(min)")
            }
            if value > max {
                problems.append("version \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a result profile.
    final class ResultProfileValidator {
        var rules: [any ResultProfileRule]

        init(rules: [any ResultProfileRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultProfile) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ResultProfile) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultProfile]) -> [String: [String]] {
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

    static func defaultResultProfileValidator() -> ResultProfileValidator {
        return ResultProfileValidator(
            rules: [
                ResultProfileChannelLengthRule(maxLength: 86400),
                ResultProfileProcedureCodeLengthRule(maxLength: 86400),
                ResultProfileVersionRangeRule(min: 255, max: 3600),
            ]
        )
    }
}
