import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a legacy program notice must pass. Check returns its problems, or none.
    protocol LegacyProgramNoticeRule {
        func check(_ item: LegacyProgramNotice) -> [String]
    }

    final class LegacyProgramNoticeRequiredLabelRule: LegacyProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProgramNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyProgramNoticeCapacityRangeRule: LegacyProgramNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyProgramNotice) -> [String] {
            let value = item.capacity
            var problems: [String] = []
            if value < min {
                problems.append("capacity \(value) is below \(min)")
            }
            if value > max {
                problems.append("capacity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class LegacyProgramNoticeDurationMinutesRangeRule: LegacyProgramNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LegacyProgramNotice) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LegacyProgramNoticeRequiredCodeRule: LegacyProgramNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacyProgramNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LegacyProgramNoticeCodeLengthRule: LegacyProgramNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacyProgramNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a legacy program notice.
    final class LegacyProgramNoticeValidator {
        var rules: [any LegacyProgramNoticeRule]

        init(rules: [any LegacyProgramNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacyProgramNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LegacyProgramNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacyProgramNotice]) -> [String: [String]] {
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

    static func defaultLegacyProgramNoticeValidator() -> LegacyProgramNoticeValidator {
        return LegacyProgramNoticeValidator(
            rules: [
                LegacyProgramNoticeRequiredLabelRule(message: "legacy program notice needs this field"),
                LegacyProgramNoticeCapacityRangeRule(min: 120, max: 255),
                LegacyProgramNoticeDurationMinutesRangeRule(min: 32, max: 120),
                LegacyProgramNoticeRequiredCodeRule(message: "legacy program notice needs an entry"),
                LegacyProgramNoticeCodeLengthRule(maxLength: 80),
            ]
        )
    }
}
