import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a manual network policy must pass. Check returns its problems, or none.
    protocol ManualNetworkPolicyRule {
        func check(_ item: ManualNetworkPolicy) -> [String]
    }

    final class ManualNetworkPolicyEndsAtRangeRule: ManualNetworkPolicyRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkPolicy) -> [String] {
            let value = item.endsAt
            if value < min || value > max {
                return ["ends at \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualNetworkPolicyWeightRangeRule: ManualNetworkPolicyRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualNetworkPolicy) -> [String] {
            let value = item.weight
            if value < min || value > max {
                return ["weight \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualNetworkPolicyWardLengthRule: ManualNetworkPolicyRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualNetworkPolicy) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual network policy.
    final class ManualNetworkPolicyValidator {
        var rules: [any ManualNetworkPolicyRule]

        init(rules: [any ManualNetworkPolicyRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualNetworkPolicy) -> [String] {
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

        func requireValid(_ item: ManualNetworkPolicy) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualNetworkPolicy]) -> [String: [String]] {
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

    static func defaultManualNetworkPolicyValidator() -> ManualNetworkPolicyValidator {
        return ManualNetworkPolicyValidator(
            rules: [
                ManualNetworkPolicyEndsAtRangeRule(min: 16, max: 32),
                ManualNetworkPolicyWeightRangeRule(min: 8.7, max: 4178.3),
                ManualNetworkPolicyWardLengthRule(maxLength: 16),
            ]
        )
    }
}
