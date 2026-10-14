import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a bed board schedule must pass. Check returns its problems, or none.
    protocol BedBoardScheduleRule {
        func check(_ item: BedBoardSchedule) -> [String]
    }

    final class BedBoardScheduleAllowedReviewerRule: BedBoardScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: BedBoardSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.reviewer)) {
                return ["reviewer \(item.reviewer) is not allowed"]
            }
            return []
        }
    }

    final class BedBoardScheduleRequiredNameRule: BedBoardScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardScheduleCodePrefixRule: BedBoardScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: BedBoardSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class BedBoardScheduleRequiredCodeRule: BedBoardScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BedBoardScheduleCodeLengthRule: BedBoardScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: BedBoardSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class BedBoardScheduleRequiredChecksumRule: BedBoardScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BedBoardSchedule) -> [String] {
            if item.checksum.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a bed board schedule.
    final class BedBoardScheduleValidator {
        var rules: [any BedBoardScheduleRule]

        init(rules: [any BedBoardScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: BedBoardSchedule) -> [String] {
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

        func requireValid(_ item: BedBoardSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BedBoardSchedule]) -> [String: [String]] {
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

    static func defaultBedBoardScheduleValidator() -> BedBoardScheduleValidator {
        return BedBoardScheduleValidator(
            rules: [
                BedBoardScheduleAllowedReviewerRule(allowed: ["pending"]),
                BedBoardScheduleRequiredNameRule(message: "bed board schedule needs a value"),
                BedBoardScheduleCodePrefixRule(prefix: "REF"),
                BedBoardScheduleRequiredCodeRule(message: "bed board schedule needs this field"),
                BedBoardScheduleCodeLengthRule(maxLength: 86400),
                BedBoardScheduleRequiredChecksumRule(message: "bed board schedule needs this field"),
            ]
        )
    }
}
