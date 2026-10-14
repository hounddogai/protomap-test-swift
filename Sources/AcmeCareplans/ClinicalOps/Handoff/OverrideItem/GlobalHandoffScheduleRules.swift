import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a global handoff schedule must pass. Check returns its problems, or none.
    protocol GlobalHandoffScheduleRule {
        func check(_ item: GlobalHandoffSchedule) -> [String]
    }

    final class GlobalHandoffScheduleMarginRangeRule: GlobalHandoffScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: GlobalHandoffSchedule) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class GlobalHandoffScheduleRequiredNameRule: GlobalHandoffScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalHandoffSchedule) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalHandoffScheduleNameLengthRule: GlobalHandoffScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalHandoffSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global handoff schedule.
    final class GlobalHandoffScheduleValidator {
        var rules: [any GlobalHandoffScheduleRule]

        init(rules: [any GlobalHandoffScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalHandoffSchedule) -> [String] {
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

        func requireValid(_ item: GlobalHandoffSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalHandoffSchedule]) -> [String: [String]] {
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

    static func defaultGlobalHandoffScheduleValidator() -> GlobalHandoffScheduleValidator {
        return GlobalHandoffScheduleValidator(
            rules: [
                GlobalHandoffScheduleMarginRangeRule(min: 9.3, max: 3385.3),
                GlobalHandoffScheduleRequiredNameRule(message: "global handoff schedule needs an entry"),
                GlobalHandoffScheduleNameLengthRule(maxLength: 120),
            ]
        )
    }
}
