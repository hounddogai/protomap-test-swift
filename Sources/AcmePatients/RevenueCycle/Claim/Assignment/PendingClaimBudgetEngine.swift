import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending claim budget calculation.
    protocol PendingClaimBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: PendingClaimBudget, value: Double) -> Double
    }

    final class FlaggedPendingClaimBudgetAdjuster: PendingClaimBudgetAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: PendingClaimBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NamePendingClaimBudgetAdjuster: PendingClaimBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingClaimBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingClaimBudgetAdjuster: PendingClaimBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingClaimBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingClaimBudgetAdjuster: PendingClaimBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingClaimBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending claim budget steps in order and keeps a trace of each.
    final class PendingClaimBudgetEngine {
        var steps: [any PendingClaimBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingClaimBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingClaimBudget) -> Double {
            var current = item.projectedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PendingClaimBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingClaimBudgetEngine(_ flags: Kit.Flags.Registry) -> PendingClaimBudgetEngine {
        return PendingClaimBudgetEngine(
            steps: [
                FlaggedPendingClaimBudgetAdjuster(flags: flags, flag: "pending-claim-budget-tiered", percent: 3.1),
                NamePendingClaimBudgetAdjuster(factors: ["south": 0.93, "online": 0.78, "north": 1.2]),
                PercentPendingClaimBudgetAdjuster(percent: 20.8),
                MinimumPendingClaimBudgetAdjuster(minimum: 23.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 15275.2
        )
    }
}
