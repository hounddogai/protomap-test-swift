import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a rolling bed board schedule must pass. Check returns its problems, or none.
    protocol RollingBedBoardScheduleRule {
        func check(_ item: RollingBedBoardSchedule) -> [String]
    }

    final class RollingBedBoardScheduleAllowedSegmentRule: RollingBedBoardScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RollingBedBoardSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.segment)) {
                return ["segment \(item.segment) is unknown"]
            }
            return []
        }
    }

    final class RollingBedBoardScheduleCodePrefixRule: RollingBedBoardScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: RollingBedBoardSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class RollingBedBoardScheduleRequiredChecksumRule: RollingBedBoardScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingBedBoardSchedule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingBedBoardScheduleRequiredCodeRule: RollingBedBoardScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingBedBoardSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingBedBoardScheduleCodeLengthRule: RollingBedBoardScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingBedBoardSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling bed board schedule.
    final class RollingBedBoardScheduleValidator {
        var rules: [any RollingBedBoardScheduleRule]

        init(rules: [any RollingBedBoardScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingBedBoardSchedule) -> [String] {
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

        func requireValid(_ item: RollingBedBoardSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingBedBoardSchedule]) -> [String: [String]] {
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

    static func defaultRollingBedBoardScheduleValidator() -> RollingBedBoardScheduleValidator {
        return RollingBedBoardScheduleValidator(
            rules: [
                RollingBedBoardScheduleAllowedSegmentRule(allowed: ["legacy", "fallback", "pending"]),
                RollingBedBoardScheduleCodePrefixRule(prefix: "Q"),
                RollingBedBoardScheduleRequiredChecksumRule(message: "rolling bed board schedule needs a value"),
                RollingBedBoardScheduleRequiredCodeRule(message: "rolling bed board schedule needs a value"),
                RollingBedBoardScheduleCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
