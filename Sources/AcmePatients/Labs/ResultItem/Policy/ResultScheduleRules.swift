import AcmePlatform
import Foundation

extension Labs {
    /// A rule a result schedule must pass. Check returns its problems, or none.
    protocol ResultScheduleRule {
        func check(_ item: ResultSchedule) -> [String]
    }

    final class ResultScheduleRequiredCodeRule: ResultScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ResultSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ResultScheduleReviewerLengthRule: ResultScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ResultSchedule) -> [String] {
            let size = item.reviewer.count
            if size > maxLength {
                return ["reviewer is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ResultScheduleCodePrefixRule: ResultScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ResultSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a result schedule.
    final class ResultScheduleValidator {
        var rules: [any ResultScheduleRule]

        init(rules: [any ResultScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ResultSchedule) -> [String] {
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

        func requireValid(_ item: ResultSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ResultSchedule]) -> [String: [String]] {
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

    static func defaultResultScheduleValidator() -> ResultScheduleValidator {
        return ResultScheduleValidator(
            rules: [
                ResultScheduleRequiredCodeRule(message: "result schedule needs an entry"),
                ResultScheduleReviewerLengthRule(maxLength: 80),
                ResultScheduleCodePrefixRule(prefix: "X"),
            ]
        )
    }
}
