import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped isolation schedule must pass. Check returns its problems, or none.
    protocol CappedIsolationScheduleRule {
        func check(_ item: CappedIsolationSchedule) -> [String]
    }

    final class CappedIsolationScheduleRequiredAllergyRule: CappedIsolationScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedIsolationSchedule) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedIsolationScheduleWeightRangeRule: CappedIsolationScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedIsolationSchedule) -> [String] {
            let value = item.weight
            var problems: [String] = []
            if value < min {
                problems.append("weight \(value) is below \(min)")
            }
            if value > max {
                problems.append("weight \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedIsolationScheduleNameLengthRule: CappedIsolationScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedIsolationSchedule) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedIsolationScheduleRequiredCodeRule: CappedIsolationScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedIsolationSchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped isolation schedule.
    final class CappedIsolationScheduleValidator {
        var rules: [any CappedIsolationScheduleRule]

        init(rules: [any CappedIsolationScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedIsolationSchedule) -> [String] {
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

        func requireValid(_ item: CappedIsolationSchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedIsolationSchedule]) -> [String: [String]] {
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

    static func defaultCappedIsolationScheduleValidator() -> CappedIsolationScheduleValidator {
        return CappedIsolationScheduleValidator(
            rules: [
                CappedIsolationScheduleRequiredAllergyRule(message: "capped isolation schedule needs an entry"),
                CappedIsolationScheduleWeightRangeRule(min: 9.2, max: 2529.8),
                CappedIsolationScheduleNameLengthRule(maxLength: 120),
                CappedIsolationScheduleRequiredCodeRule(message: "capped isolation schedule needs an entry"),
            ]
        )
    }
}
