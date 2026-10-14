import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary reference range schedule must pass. Check returns its problems, or none.
    protocol PrimaryReferenceRangeScheduleRule {
        func check(_ item: PrimaryReferenceRangeSchedule) -> [String]
    }

    final class PrimaryReferenceRangeScheduleCodeLengthRule: PrimaryReferenceRangeScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryReferenceRangeSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryReferenceRangeScheduleRequiredTitleRule: PrimaryReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferenceRangeSchedule) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryReferenceRangeScheduleBatchSizeRangeRule: PrimaryReferenceRangeScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryReferenceRangeSchedule) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class PrimaryReferenceRangeScheduleRequiredChannelRule: PrimaryReferenceRangeScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryReferenceRangeSchedule) -> [String] {
            if item.channel.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary reference range schedule.
    final class PrimaryReferenceRangeScheduleValidator {
        var rules: [any PrimaryReferenceRangeScheduleRule]

        init(rules: [any PrimaryReferenceRangeScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryReferenceRangeSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: PrimaryReferenceRangeSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryReferenceRangeSchedule]) -> [String: [String]] {
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

    static func defaultPrimaryReferenceRangeScheduleValidator() -> PrimaryReferenceRangeScheduleValidator {
        return PrimaryReferenceRangeScheduleValidator(
            rules: [
                PrimaryReferenceRangeScheduleCodeLengthRule(maxLength: 64),
                PrimaryReferenceRangeScheduleRequiredTitleRule(
                    message: "primary reference range schedule needs a value"
                ),
                PrimaryReferenceRangeScheduleBatchSizeRangeRule(min: 1000, max: 1000),
                PrimaryReferenceRangeScheduleRequiredChannelRule(
                    message: "primary reference range schedule needs a value"
                ),
            ]
        )
    }
}
