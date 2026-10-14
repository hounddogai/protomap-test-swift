import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up cycle must pass. Check returns its problems, or none.
    protocol FollowUpCycleRule {
        func check(_ item: FollowUpCycle) -> [String]
    }

    final class FollowUpCycleBatchSizeRangeRule: FollowUpCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpCycle) -> [String] {
            let value = item.batchSize
            if value < min || value > max {
                return ["batch size \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpCycleRequiredCodeRule: FollowUpCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpCycleExpiresAtRangeRule: FollowUpCycleRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpCycle) -> [String] {
            let value = item.expiresAt
            if value < min || value > max {
                return ["expires at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class FollowUpCycleMarginRangeRule: FollowUpCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: FollowUpCycle) -> [String] {
            let value = item.margin
            if value < min || value > max {
                return ["margin \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a follow up cycle.
    final class FollowUpCycleValidator {
        var rules: [any FollowUpCycleRule]

        init(rules: [any FollowUpCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpCycle) -> [String] {
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

        func requireValid(_ item: FollowUpCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpCycle]) -> [String: [String]] {
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

    static func defaultFollowUpCycleValidator() -> FollowUpCycleValidator {
        return FollowUpCycleValidator(
            rules: [
                FollowUpCycleBatchSizeRangeRule(min: 32, max: 120),
                FollowUpCycleRequiredCodeRule(message: "follow up cycle needs this field"),
                FollowUpCycleExpiresAtRangeRule(min: 120, max: 1000),
                FollowUpCycleMarginRangeRule(min: 7.9, max: 4551.7),
            ]
        )
    }
}
