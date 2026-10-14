import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global rounding schedule must pass. Check returns its problems, or none.
    protocol GlobalRoundingScheduleRule {
        func check(_ item: GlobalRoundingSchedule) -> [String]
    }

    final class GlobalRoundingScheduleAllowedPayerRule: GlobalRoundingScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalRoundingSchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.payer)) {
                return ["payer \(item.payer) is missing"]
            }
            return []
        }
    }

    final class GlobalRoundingScheduleLabelLengthRule: GlobalRoundingScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRoundingSchedule) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class GlobalRoundingScheduleTitleLengthRule: GlobalRoundingScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRoundingSchedule) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global rounding schedule.
    final class GlobalRoundingScheduleValidator {
        var rules: [any GlobalRoundingScheduleRule]

        init(rules: [any GlobalRoundingScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRoundingSchedule) -> [String] {
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

        func requireValid(_ item: GlobalRoundingSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRoundingSchedule]) -> [String: [String]] {
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

    static func defaultGlobalRoundingScheduleValidator() -> GlobalRoundingScheduleValidator {
        return GlobalRoundingScheduleValidator(
            rules: [
                GlobalRoundingScheduleAllowedPayerRule(allowed: ["global"]),
                GlobalRoundingScheduleLabelLengthRule(maxLength: 86400),
                GlobalRoundingScheduleTitleLengthRule(maxLength: 86400),
            ]
        )
    }
}
