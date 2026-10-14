import AcmePlatform
import Foundation

extension Labs {
    /// A rule a primary panel schedule must pass. Check returns its problems, or none.
    protocol PrimaryPanelScheduleRule {
        func check(_ item: PrimaryPanelSchedule) -> [String]
    }

    final class PrimaryPanelScheduleSourceLengthRule: PrimaryPanelScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryPanelSchedule) -> [String] {
            let size = item.source.count
            if size > maxLength {
                return ["source is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryPanelScheduleNameLengthRule: PrimaryPanelScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: PrimaryPanelSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class PrimaryPanelScheduleRequiredSourceRule: PrimaryPanelScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryPanelSchedule) -> [String] {
            if item.source.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryPanelScheduleRateRangeRule: PrimaryPanelScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: PrimaryPanelSchedule) -> [String] {
            let value = item.rate
            var problems: [String] = []
            if value < min {
                problems.append("rate \(value) is below \(min)")
            }
            if value > max {
                problems.append("rate \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a primary panel schedule.
    final class PrimaryPanelScheduleValidator {
        var rules: [any PrimaryPanelScheduleRule]

        init(rules: [any PrimaryPanelScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryPanelSchedule) -> [String] {
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

        func requireValid(_ item: PrimaryPanelSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryPanelSchedule]) -> [String: [String]] {
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

    static func defaultPrimaryPanelScheduleValidator() -> PrimaryPanelScheduleValidator {
        return PrimaryPanelScheduleValidator(
            rules: [
                PrimaryPanelScheduleSourceLengthRule(maxLength: 80),
                PrimaryPanelScheduleNameLengthRule(maxLength: 120),
                PrimaryPanelScheduleRequiredSourceRule(message: "primary panel schedule needs an entry"),
                PrimaryPanelScheduleRateRangeRule(min: 1.7, max: 2842.3),
            ]
        )
    }
}
