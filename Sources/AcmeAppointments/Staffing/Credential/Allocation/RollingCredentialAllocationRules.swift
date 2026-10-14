import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a rolling credential allocation must pass. Check returns its problems, or none.
    protocol RollingCredentialAllocationRule {
        func check(_ item: RollingCredentialAllocation) -> [String]
    }

    final class RollingCredentialAllocationQuantityRangeRule: RollingCredentialAllocationRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCredentialAllocation) -> [String] {
            let value = item.quantity
            var problems: [String] = []
            if value < min {
                problems.append("quantity \(value) is below \(min)")
            }
            if value > max {
                problems.append("quantity \(value) is above \(max)")
            }
            return problems
        }
    }

    final class RollingCredentialAllocationRequiredTitleRule: RollingCredentialAllocationRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingCredentialAllocation) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RollingCredentialAllocationCostRangeRule: RollingCredentialAllocationRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: RollingCredentialAllocation) -> [String] {
            let value = item.cost
            if value < min || value > max {
                return ["cost \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    /// Runs every rule of a rolling credential allocation.
    final class RollingCredentialAllocationValidator {
        var rules: [any RollingCredentialAllocationRule]

        init(rules: [any RollingCredentialAllocationRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingCredentialAllocation) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingCredentialAllocation) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingCredentialAllocation]) -> [String: [String]] {
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

    static func defaultRollingCredentialAllocationValidator() -> RollingCredentialAllocationValidator {
        return RollingCredentialAllocationValidator(
            rules: [
                RollingCredentialAllocationQuantityRangeRule(min: 16, max: 32),
                RollingCredentialAllocationRequiredTitleRule(message: "rolling credential allocation needs an entry"),
                RollingCredentialAllocationCostRangeRule(min: 7.6, max: 4147.8),
            ]
        )
    }
}
