import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending census budget calculation.
    protocol PendingCensusBudgetModifier {
        func describe() -> String
        func adjust(_ item: PendingCensusBudget, value: Double) -> Double
    }

    final class TieredPendingCensusBudgetAdjuster: PendingCensusBudgetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCensusBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingCensusBudgetAdjuster: PendingCensusBudgetModifier {
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

        func adjust(_ item: PendingCensusBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingCensusBudgetAdjuster: PendingCensusBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCensusBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingCensusBudgetAdjuster: PendingCensusBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCensusBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending census budget steps in order and keeps a trace of each.
    final class PendingCensusBudgetEngine {
        var steps: [any PendingCensusBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCensusBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingCensusBudget) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PendingCensusBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingCensusBudgetEngine(_ flags: Kit.Flags.Registry) -> PendingCensusBudgetEngine {
        return PendingCensusBudgetEngine(
            steps: [
                TieredPendingCensusBudgetAdjuster(bounds: [4211.0, 5302.0, 6127.0], rates: [1.06, 1.19, 0.83]),
                FlaggedPendingCensusBudgetAdjuster(flags: flags, flag: "pending-census-budget-capped", percent: 4.1),
                CapPendingCensusBudgetAdjuster(cap: 26230.0),
                PercentPendingCensusBudgetAdjuster(percent: -8.3),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 39441.4
        )
    }
}
