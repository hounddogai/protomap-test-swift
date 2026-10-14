import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a default denial cycle must pass. Check returns its problems, or none.
    protocol DefaultDenialCycleRule {
        func check(_ item: DefaultDenialCycle) -> [String]
    }

    final class DefaultDenialCycleTitleLengthRule: DefaultDenialCycleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: DefaultDenialCycle) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class DefaultDenialCycleWindowDaysRangeRule: DefaultDenialCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: DefaultDenialCycle) -> [String] {
            let value = item.windowDays
            if value < min || value > max {
                return ["window days \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class DefaultDenialCycleRequiredLocaleRule: DefaultDenialCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDenialCycle) -> [String] {
            if item.locale.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class DefaultDenialCycleApprovedGuardRule: DefaultDenialCycleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: DefaultDenialCycle) -> [String] {
            if item.approved && (item.windowDays > limit) {
                return ["window days \(item.windowDays) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class DefaultDenialCycleRequiredUnitRule: DefaultDenialCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: DefaultDenialCycle) -> [String] {
            if item.unit.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a default denial cycle.
    final class DefaultDenialCycleValidatorExtra {
        var rules: [any DefaultDenialCycleRule]

        init(rules: [any DefaultDenialCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: DefaultDenialCycle) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: DefaultDenialCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [DefaultDenialCycle]) -> [String: [String]] {
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

    static func defaultDefaultDenialCycleValidator() -> DefaultDenialCycleValidatorExtra {
        return DefaultDenialCycleValidatorExtra(
            rules: [
                DefaultDenialCycleTitleLengthRule(maxLength: 32),
                DefaultDenialCycleWindowDaysRangeRule(min: 32, max: 255),
                DefaultDenialCycleRequiredLocaleRule(message: "default denial cycle needs an entry"),
                DefaultDenialCycleApprovedGuardRule(limit: 255),
                DefaultDenialCycleRequiredUnitRule(message: "default denial cycle needs this field"),
            ]
        )
    }
}
