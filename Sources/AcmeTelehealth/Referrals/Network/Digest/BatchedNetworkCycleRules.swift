import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a batched network cycle must pass. Check returns its problems, or none.
    protocol BatchedNetworkCycleRule {
        func check(_ item: BatchedNetworkCycle) -> [String]
    }

    final class BatchedNetworkCycleAmountRangeRule: BatchedNetworkCycleRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: BatchedNetworkCycle) -> [String] {
            let value = item.amount
            var problems: [String] = []
            if value < min {
                problems.append("amount \(value) is below \(min)")
            }
            if value > max {
                problems.append("amount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class BatchedNetworkCycleRequiredCodeRule: BatchedNetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedNetworkCycle) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class BatchedNetworkCycleRequiredLabelRule: BatchedNetworkCycleRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: BatchedNetworkCycle) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a batched network cycle.
    final class BatchedNetworkCycleValidator {
        var rules: [any BatchedNetworkCycleRule]

        init(rules: [any BatchedNetworkCycleRule]) {
            self.rules = rules
        }

        func validate(_ item: BatchedNetworkCycle) -> [String] {
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

        func requireValid(_ item: BatchedNetworkCycle) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [BatchedNetworkCycle]) -> [String: [String]] {
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

    static func defaultBatchedNetworkCycleValidator() -> BatchedNetworkCycleValidator {
        return BatchedNetworkCycleValidator(
            rules: [
                BatchedNetworkCycleAmountRangeRule(min: 4.2, max: 3322.7),
                BatchedNetworkCycleRequiredCodeRule(message: "batched network cycle needs an entry"),
                BatchedNetworkCycleRequiredLabelRule(message: "batched network cycle needs a value"),
            ]
        )
    }
}
