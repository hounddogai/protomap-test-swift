import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a remittance schedule must pass. Check returns its problems, or none.
    protocol RemittanceScheduleRule {
        func check(_ item: RemittanceSchedule) -> [String]
    }

    final class RemittanceScheduleCodeLengthRule: RemittanceScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RemittanceSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RemittanceScheduleRequiredTitleRule: RemittanceScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RemittanceSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RemittanceScheduleCodePrefixRule: RemittanceScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RemittanceSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a remittance schedule.
    final class RemittanceScheduleValidator {
        var rules: [any RemittanceScheduleRule]

        init(rules: [any RemittanceScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RemittanceSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RemittanceSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RemittanceSchedule]) -> [String: [String]] {
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

    static func defaultRemittanceScheduleValidator() -> RemittanceScheduleValidator {
        return RemittanceScheduleValidator(
            rules: [
                RemittanceScheduleCodeLengthRule(maxLength: 80),
                RemittanceScheduleRequiredTitleRule(message: "remittance schedule needs an entry"),
                RemittanceScheduleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
