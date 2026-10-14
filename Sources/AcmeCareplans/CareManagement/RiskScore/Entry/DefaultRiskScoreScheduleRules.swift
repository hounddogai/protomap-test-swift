import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a default risk score schedule must pass. Check returns its problems, or none.
    protocol DefaultRiskScoreScheduleRule {
        func check(_ item: DefaultRiskScoreSchedule) -> [String]
    }

    final class DefaultRiskScoreScheduleNameLengthRule: DefaultRiskScoreScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreScheduleCodePrefixRule: DefaultRiskScoreScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: DefaultRiskScoreSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class DefaultRiskScoreScheduleSummaryLengthRule: DefaultRiskScoreScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultRiskScoreSchedule) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a default risk score schedule.
    final class DefaultRiskScoreScheduleValidator {
        var rules: [any DefaultRiskScoreScheduleRule]

        init(rules: [any DefaultRiskScoreScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultRiskScoreSchedule) -> [String] {
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

        func requireValid(_ item: DefaultRiskScoreSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultRiskScoreSchedule]) -> [String: [String]] {
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

    static func defaultDefaultRiskScoreScheduleValidator() -> DefaultRiskScoreScheduleValidator {
        return DefaultRiskScoreScheduleValidator(
            rules: [
                DefaultRiskScoreScheduleNameLengthRule(maxLength: 3600),
                DefaultRiskScoreScheduleCodePrefixRule(prefix: "Q"),
                DefaultRiskScoreScheduleSummaryLengthRule(maxLength: 64),
            ]
        )
    }
}
