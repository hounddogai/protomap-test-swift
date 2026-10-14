import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a strict claim allocation must pass. Check returns its problems, or none.
    protocol StrictClaimAllocationRule {
        func check(_ item: StrictClaimAllocation) -> [String]
    }

    final class StrictClaimAllocationRequiredRegionRule: StrictClaimAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimAllocation) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class StrictClaimAllocationRevisionRangeRule: StrictClaimAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimAllocation) -> [String] {
            let value = item.revision
            var problems: [String] = []
            if value < min {
                problems.append("revision \(value) is below \(min)")
            }
            if value > max {
                problems.append("revision \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictClaimAllocationVisibleGuardRule: StrictClaimAllocationRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: StrictClaimAllocation) -> [String] {
            if item.visible && (item.startsAt > limit) {
                return ["starts at \(item.startsAt) exceeds \(limit) while visible"]
            }
            return []
        }
    }

    final class StrictClaimAllocationUpdatedAtRangeRule: StrictClaimAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimAllocation) -> [String] {
            let value = item.updatedAt
            var problems: [String] = []
            if value < min {
                problems.append("updated at \(value) is below \(min)")
            }
            if value > max {
                problems.append("updated at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class StrictClaimAllocationStartsAtRangeRule: StrictClaimAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: StrictClaimAllocation) -> [String] {
            let value = item.startsAt
            if value < min || value > max {
                return ["starts at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class StrictClaimAllocationRequiredCodeRule: StrictClaimAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: StrictClaimAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a strict claim allocation.
    final class StrictClaimAllocationValidator {
        var rules: [any StrictClaimAllocationRule]

        init(rules: [any StrictClaimAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: StrictClaimAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: StrictClaimAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [StrictClaimAllocation]) -> [String: [String]] {
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

    static func defaultStrictClaimAllocationValidator() -> StrictClaimAllocationValidator {
        return StrictClaimAllocationValidator(
            rules: [
                StrictClaimAllocationRequiredRegionRule(message: "strict claim allocation needs an entry"),
                StrictClaimAllocationRevisionRangeRule(min: 16, max: 86400),
                StrictClaimAllocationVisibleGuardRule(limit: 16),
                StrictClaimAllocationUpdatedAtRangeRule(min: 120, max: 255),
                StrictClaimAllocationStartsAtRangeRule(min: 255, max: 1000),
                StrictClaimAllocationRequiredCodeRule(message: "strict claim allocation needs an entry"),
            ]
        )
    }
}
