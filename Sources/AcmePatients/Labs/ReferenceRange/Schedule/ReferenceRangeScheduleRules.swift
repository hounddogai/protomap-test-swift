import AcmePlatform
import Foundation

extension Labs {
    /// A rule a reference range schedule must pass. Check returns its problems, or none.
    protocol ReferenceRangeScheduleRule {
        func check(_ item: ReferenceRangeSchedule) -> [String]
    }

    final class ReferenceRangeScheduleRequiredChannelRule: ReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeSchedule) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeScheduleNameLengthRule: ReferenceRangeScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeScheduleCodeLengthRule: ReferenceRangeScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ReferenceRangeSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ReferenceRangeScheduleRequiredNameRule: ReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ReferenceRangeScheduleRequiredCodeRule: ReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ReferenceRangeSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a reference range schedule.
    final class ReferenceRangeScheduleValidator {
        var rules: [any ReferenceRangeScheduleRule]

        init(rules: [any ReferenceRangeScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: ReferenceRangeSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ReferenceRangeSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ReferenceRangeSchedule]) -> [String: [String]] {
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

    static func defaultReferenceRangeScheduleValidator() -> ReferenceRangeScheduleValidator {
        return ReferenceRangeScheduleValidator(
            rules: [
                ReferenceRangeScheduleRequiredChannelRule(message: "reference range schedule needs an entry"),
                ReferenceRangeScheduleNameLengthRule(maxLength: 1000),
                ReferenceRangeScheduleCodeLengthRule(maxLength: 86400),
                ReferenceRangeScheduleRequiredNameRule(message: "reference range schedule needs an entry"),
                ReferenceRangeScheduleRequiredCodeRule(message: "reference range schedule needs an entry"),
            ]
        )
    }
}
