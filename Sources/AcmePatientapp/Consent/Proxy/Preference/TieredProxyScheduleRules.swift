import AcmePlatform
import Foundation

extension Consent {
    /// A rule a tiered proxy schedule must pass. Check returns its problems, or none.
    protocol TieredProxyScheduleRule {
        func check(_ item: TieredProxySchedule) -> [String]
    }

    final class TieredProxyScheduleBudgetRangeRule: TieredProxyScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProxySchedule) -> [String] {
            let value = item.budget
            var problems: [String] = []
            if value < min {
                problems.append("budget \(value) is below \(min)")
            }
            if value > max {
                problems.append("budget \(value) is above \(max)")
            }
            return problems
        }
    }

    final class TieredProxyScheduleApprovedGuardRule: TieredProxyScheduleRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: TieredProxySchedule) -> [String] {
            if item.approved && (item.refills > limit) {
                return ["refills \(item.refills) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class TieredProxyScheduleRequiredSegmentRule: TieredProxyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredProxySchedule) -> [String] {
            if item.segment.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredProxyScheduleCurrencyLengthRule: TieredProxyScheduleRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: TieredProxySchedule) -> [String] {
            let size = item.currency.count
            if size > maxLength {
                return ["currency is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class TieredProxyScheduleRequiredCodeRule: TieredProxyScheduleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: TieredProxySchedule) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class TieredProxyScheduleCopayRangeRule: TieredProxyScheduleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: TieredProxySchedule) -> [String] {
            let value = item.copay
            var problems: [String] = []
            if value < min {
                problems.append("copay \(value) is below \(min)")
            }
            if value > max {
                problems.append("copay \(value) is above \(max)")
            }
            return problems
        }
    }

    /// Runs every rule of a tiered proxy schedule.
    final class TieredProxyScheduleValidator {
        var rules: [any TieredProxyScheduleRule]

        init(rules: [any TieredProxyScheduleRule]) {
            self.rules = rules
        }

        func validate(_ item: TieredProxySchedule) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: TieredProxySchedule) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [TieredProxySchedule]) -> [String: [String]] {
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

    static func defaultTieredProxyScheduleValidator() -> TieredProxyScheduleValidator {
        return TieredProxyScheduleValidator(
            rules: [
                TieredProxyScheduleBudgetRangeRule(min: 4.1, max: 3865.5),
                TieredProxyScheduleApprovedGuardRule(limit: 80),
                TieredProxyScheduleRequiredSegmentRule(message: "tiered proxy schedule needs a value"),
                TieredProxyScheduleCurrencyLengthRule(maxLength: 64),
                TieredProxyScheduleRequiredCodeRule(message: "tiered proxy schedule needs an entry"),
                TieredProxyScheduleCopayRangeRule(min: 8.3, max: 731.8),
            ]
        )
    }
}
