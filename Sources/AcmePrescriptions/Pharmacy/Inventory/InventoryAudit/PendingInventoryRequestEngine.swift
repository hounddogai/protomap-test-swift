import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending inventory request calculation.
    protocol PendingInventoryRequestFactor {
        func describe() -> String
        func adjust(_ item: PendingInventoryRequest, value: Double) -> Double
    }

    final class CapPendingInventoryRequestAdjuster: PendingInventoryRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingInventoryRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPendingInventoryRequestAdjuster: PendingInventoryRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingInventoryRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPendingInventoryRequestAdjuster: PendingInventoryRequestFactor {
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

        func adjust(_ item: PendingInventoryRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingInventoryRequestAdjuster: PendingInventoryRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingInventoryRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryPendingInventoryRequestAdjuster: PendingInventoryRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PendingInventoryRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingInventoryRequestAdjuster: PendingInventoryRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingInventoryRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending inventory request steps in order and keeps a trace of each.
    final class PendingInventoryRequestEngine {
        var steps: [any PendingInventoryRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingInventoryRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingInventoryRequest) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingInventoryRequestFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [PendingInventoryRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingInventoryRequestEngine(_ flags: Kit.Flags.Registry) -> PendingInventoryRequestEngine {
        return PendingInventoryRequestEngine(
            steps: [
                CapPendingInventoryRequestAdjuster(cap: 37277.0),
                RoundingPendingInventoryRequestAdjuster(step: 0.05),
                FlaggedPendingInventoryRequestAdjuster(
                    flags: flags,
                    flag: "pending-inventory-request-capped",
                    percent: 5.2
                ),
                TieredPendingInventoryRequestAdjuster(bounds: [1002.0, 5965.0], rates: [0.93, 0.93]),
                CountryPendingInventoryRequestAdjuster(factors: ["retail": 0.86]),
                PercentPendingInventoryRequestAdjuster(percent: -24.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 22935.0
        )
    }
}
