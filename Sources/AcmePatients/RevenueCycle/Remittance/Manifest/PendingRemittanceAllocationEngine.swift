import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending remittance allocation calculation.
    protocol PendingRemittanceAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: PendingRemittanceAllocation, value: Double) -> Double
    }

    final class TieredPendingRemittanceAllocationAdjuster: PendingRemittanceAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingRemittanceAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedPendingRemittanceAllocationAdjuster: PendingRemittanceAllocationAdjuster {
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

        func adjust(_ item: PendingRemittanceAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingRemittanceAllocationRetriesOffsetAdjuster: PendingRemittanceAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PendingRemittanceAllocation, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumPendingRemittanceAllocationAdjuster: PendingRemittanceAllocationAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingRemittanceAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPendingRemittanceAllocationAdjuster: PendingRemittanceAllocationAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingRemittanceAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending remittance allocation steps in order and keeps a trace of each.
    final class PendingRemittanceAllocationEngine {
        var steps: [any PendingRemittanceAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRemittanceAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingRemittanceAllocation) -> Double {
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

        func evaluateAll(_ items: [PendingRemittanceAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingRemittanceAllocationEngine(_ flags: Kit.Flags.Registry) -> PendingRemittanceAllocationEngine {
        return PendingRemittanceAllocationEngine(
            steps: [
                TieredPendingRemittanceAllocationAdjuster(
                    bounds: [8200.0, 9613.0, 10000.0],
                    rates: [0.84, 1.15, 0.95]
                ),
                FlaggedPendingRemittanceAllocationAdjuster(
                    flags: flags,
                    flag: "pending-remittance-allocation-batched",
                    percent: 2.1
                ),
                PendingRemittanceAllocationRetriesOffsetAdjuster(weight: 1.62),
                MinimumPendingRemittanceAllocationAdjuster(minimum: 37.2),
                PercentPendingRemittanceAllocationAdjuster(percent: 3.4),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 17414.6
        )
    }
}
