import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a tiered priority schedule must pass. Check returns its problems, or none.
    protocol TieredPriorityScheduleRule {
        func check(_ item: TieredPrioritySchedule) -> [String]
    }

    final class TieredPriorityScheduleCodeLengthRule: TieredPriorityScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPrioritySchedule) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPriorityScheduleRequiredCountryRule: TieredPriorityScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredPrioritySchedule) -> [String] {
            if item.country.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredPriorityScheduleWeightRangeRule: TieredPriorityScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredPrioritySchedule) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class TieredPriorityScheduleApprovedGuardRule: TieredPriorityScheduleRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: TieredPrioritySchedule) -> [String] {
            if item.approved && (item.weight > limit) {
                return ["weight \(item.weight) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredPriorityScheduleCountryLengthRule: TieredPriorityScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredPrioritySchedule) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredPriorityScheduleAllowedCountryRule: TieredPriorityScheduleRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: TieredPrioritySchedule) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.country)) {
                return ["country \(item.country) is blocked"]
            }
            return []
        }
    }

    /// Runs every rule of a tiered priority schedule.
    final class TieredPriorityScheduleValidator {
        var rules: [any TieredPriorityScheduleRule]

        init(rules: [any TieredPriorityScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredPrioritySchedule) -> [String] {
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

        func requireValid(_ item: TieredPrioritySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredPrioritySchedule]) -> [String: [String]] {
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

    static func defaultTieredPriorityScheduleValidator() -> TieredPriorityScheduleValidator {
        return TieredPriorityScheduleValidator(
            rules: [
                TieredPriorityScheduleCodeLengthRule(maxLength: 3600),
                TieredPriorityScheduleRequiredCountryRule(message: "tiered priority schedule needs an entry"),
                TieredPriorityScheduleWeightRangeRule(min: 5.4, max: 4951.0),
                TieredPriorityScheduleApprovedGuardRule(limit: 1.5),
                TieredPriorityScheduleCountryLengthRule(maxLength: 32),
                TieredPriorityScheduleAllowedCountryRule(allowed: ["regional"]),
            ]
        )
    }
}
