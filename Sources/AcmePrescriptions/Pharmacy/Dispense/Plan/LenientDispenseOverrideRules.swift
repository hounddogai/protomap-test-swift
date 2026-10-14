import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a lenient dispense override must pass. Check returns its problems, or none.
    protocol LenientDispenseOverrideRule {
        func check(_ item: LenientDispenseOverride) -> [String]
    }

    final class LenientDispenseOverrideRequiredTitleRule: LenientDispenseOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseOverride) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseOverrideRequiredCodeRule: LenientDispenseOverrideRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LenientDispenseOverride) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class LenientDispenseOverrideWindowDaysRangeRule: LenientDispenseOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDispenseOverride) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class LenientDispenseOverrideDurationMinutesRangeRule: LenientDispenseOverrideRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: LenientDispenseOverride) -> [String] {
            let value = item.durationMinutes
            var problems: [String] = []
            if value < min {
                problems.append("duration minutes \(value) is below \(min)")
            }
            if value > max {
                problems.append("duration minutes \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a lenient dispense override.
    final class LenientDispenseOverrideValidator {
        var rules: [any LenientDispenseOverrideRule]

        init(rules: [any LenientDispenseOverrideRule]) {
            self.rules = rules
        }

        func validate(_ item: LenientDispenseOverride) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: LenientDispenseOverride) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LenientDispenseOverride]) -> [String: [String]] {
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

    static func defaultLenientDispenseOverrideValidator() -> LenientDispenseOverrideValidator {
        return LenientDispenseOverrideValidator(
            rules: [
                LenientDispenseOverrideRequiredTitleRule(message: "lenient dispense override needs this field"),
                LenientDispenseOverrideRequiredCodeRule(message: "lenient dispense override needs a value"),
                LenientDispenseOverrideWindowDaysRangeRule(min: 120, max: 255),
                LenientDispenseOverrideDurationMinutesRangeRule(min: 16, max: 255),
            ]
        )
    }
}
