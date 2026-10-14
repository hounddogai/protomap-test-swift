import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a strict overtime override must pass. Check returns its problems, or none.
    protocol StrictOvertimeOverrideRule {
        func check(_ item: StrictOvertimeOverride) -> [String]
    }

    final class StrictOvertimeOverrideCostRangeRule: StrictOvertimeOverrideRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOvertimeOverride) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictOvertimeOverrideTitleLengthRule: StrictOvertimeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOvertimeOverride) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class StrictOvertimeOverrideDurationMinutesRangeRule: StrictOvertimeOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictOvertimeOverride) -> [String] {
            let value = item.durationMinutes
            if value < min || value > max {
                return ["duration minutes \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictOvertimeOverrideCodeLengthRule: StrictOvertimeOverrideRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: StrictOvertimeOverride) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a strict overtime override.
    final class StrictOvertimeOverrideValidator {
        var rules: [any StrictOvertimeOverrideRule]

        init(rules: [any StrictOvertimeOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictOvertimeOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictOvertimeOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictOvertimeOverride]) -> [String: [String]] {
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

    static func defaultStrictOvertimeOverrideValidator() -> StrictOvertimeOverrideValidator {
        return StrictOvertimeOverrideValidator(
            rules: [
                StrictOvertimeOverrideCostRangeRule(min: 0.8, max: 3404.5),
                StrictOvertimeOverrideTitleLengthRule(maxLength: 32),
                StrictOvertimeOverrideDurationMinutesRangeRule(min: 64, max: 3600),
                StrictOvertimeOverrideCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
