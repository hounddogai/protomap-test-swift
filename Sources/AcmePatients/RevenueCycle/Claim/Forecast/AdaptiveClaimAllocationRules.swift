import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a adaptive claim allocation must pass. Check returns its problems, or none.
    protocol AdaptiveClaimAllocationRule {
        func check(_ item: AdaptiveClaimAllocation) -> [String]
    }

    final class AdaptiveClaimAllocationAttemptsRangeRule: AdaptiveClaimAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveClaimAllocation) -> [String] {
            let value = item.attempts
            var problems: [String] = []
            if value < min {
                problems.append("attempts \(value) is below \(min)")
            }
            if value > max {
                problems.append("attempts \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveClaimAllocationRequiredNameRule: AdaptiveClaimAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClaimAllocation) -> [String] {
            if item.name.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveClaimAllocationRequiredCodeRule: AdaptiveClaimAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: AdaptiveClaimAllocation) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class AdaptiveClaimAllocationCeilingRangeRule: AdaptiveClaimAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveClaimAllocation) -> [String] {
            let value = item.ceiling
            var problems: [String] = []
            if value < min {
                problems.append("ceiling \(value) is below \(min)")
            }
            if value > max {
                problems.append("ceiling \(value) is above \(max)")
            }
            return problems
        }
    }

    final class AdaptiveClaimAllocationMinimumRangeRule: AdaptiveClaimAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: AdaptiveClaimAllocation) -> [String] {
            let value = item.minimum
            if value < min || value > max {
                return ["minimum \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a adaptive claim allocation.
    final class AdaptiveClaimAllocationValidator {
        var rules: [any AdaptiveClaimAllocationRule]

        init(rules: [any AdaptiveClaimAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: AdaptiveClaimAllocation) -> [String] {
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

        func requireValid(_ item: AdaptiveClaimAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [AdaptiveClaimAllocation]) -> [String: [String]] {
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

    static func defaultAdaptiveClaimAllocationValidator() -> AdaptiveClaimAllocationValidator {
        return AdaptiveClaimAllocationValidator(
            rules: [
                AdaptiveClaimAllocationAttemptsRangeRule(min: 16, max: 3600),
                AdaptiveClaimAllocationRequiredNameRule(message: "adaptive claim allocation needs an entry"),
                AdaptiveClaimAllocationRequiredCodeRule(message: "adaptive claim allocation needs a value"),
                AdaptiveClaimAllocationCeilingRangeRule(min: 4.5, max: 4435.4),
                AdaptiveClaimAllocationMinimumRangeRule(min: 1.3, max: 205.4),
            ]
        )
    }
}
