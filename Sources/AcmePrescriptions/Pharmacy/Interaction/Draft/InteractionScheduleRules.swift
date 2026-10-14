import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction schedule must pass. Check returns its problems, or none.
    protocol InteractionScheduleRule {
        func check(_ item: InteractionSchedule) -> [String]
    }

    final class InteractionScheduleCodePrefixRule: InteractionScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionScheduleLimitRangeRule: InteractionScheduleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: InteractionSchedule) -> [String] {
            let value = item.limit
            if value < min || value > max {
                return ["limit \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class InteractionScheduleCodeLengthRule: InteractionScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionScheduleRequiredChecksumRule: InteractionScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionSchedule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction schedule.
    final class InteractionScheduleValidator {
        var rules: [any InteractionScheduleRule]

        init(rules: [any InteractionScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionSchedule) -> [String] {
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

        func requireValid(_ item: InteractionSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionSchedule]) -> [String: [String]] {
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

    static func defaultInteractionScheduleValidator() -> InteractionScheduleValidator {
        return InteractionScheduleValidator(
            rules: [
                InteractionScheduleCodePrefixRule(prefix: "X"),
                InteractionScheduleLimitRangeRule(min: 255, max: 255),
                InteractionScheduleCodeLengthRule(maxLength: 86400),
                InteractionScheduleRequiredChecksumRule(message: "interaction schedule needs this field"),
            ]
        )
    }
}
