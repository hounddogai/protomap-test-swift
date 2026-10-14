import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol schedule must pass. Check returns its problems, or none.
    protocol CareProtocolScheduleRule {
        func check(_ item: CareProtocolSchedule) -> [String]
    }

    final class CareProtocolSchedulePhoneLengthRule: CareProtocolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            let size = item.phone.count
            if size > maxLength {
                return ["phone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolScheduleCodeLengthRule: CareProtocolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolScheduleTitleLengthRule: CareProtocolScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolScheduleCodePrefixRule: CareProtocolScheduleRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolSchedule) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol schedule.
    final class CareProtocolScheduleValidator {
        var rules: [any CareProtocolScheduleRule]

        init(rules: [any CareProtocolScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolSchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CareProtocolSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolSchedule]) -> [String: [String]] {
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

    static func defaultCareProtocolScheduleValidator() -> CareProtocolScheduleValidator {
        return CareProtocolScheduleValidator(
            rules: [
                CareProtocolSchedulePhoneLengthRule(maxLength: 16),
                CareProtocolScheduleCodeLengthRule(maxLength: 80),
                CareProtocolScheduleTitleLengthRule(maxLength: 255),
                CareProtocolScheduleCodePrefixRule(prefix: "OPS"),
            ]
        )
    }
}
