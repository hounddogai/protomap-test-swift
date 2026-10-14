import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary shift allocation calculation.
    protocol PrimaryShiftAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryShiftAllocation, value: Double) -> Double
    }

    final class FlaggedPrimaryShiftAllocationAdjuster: PrimaryShiftAllocationAdjuster {
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

        func adjust(_ item: PrimaryShiftAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryShiftAllocationAdjuster: PrimaryShiftAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryShiftAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PrimaryShiftAllocationBudgetOffsetAdjuster: PrimaryShiftAllocationAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: PrimaryShiftAllocation, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the primary shift allocation steps in order and keeps a trace of each.
    final class PrimaryShiftAllocationEngine {
        var steps: [any PrimaryShiftAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryShiftAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryShiftAllocation) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [PrimaryShiftAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryShiftAllocationEngine(_ flags: Kit.Flags.Registry) -> PrimaryShiftAllocationEngine {
        return PrimaryShiftAllocationEngine(
            steps: [
                FlaggedPrimaryShiftAllocationAdjuster(
                    flags: flags,
                    flag: "primary-shift-allocation-fallback",
                    percent: -8.4
                ),
                TieredPrimaryShiftAllocationAdjuster(
                    bounds: [1745.0, 3070.0, 7873.0, 9874.0],
                    rates: [0.96, 1.19, 1.03, 0.87]
                ),
                PrimaryShiftAllocationBudgetOffsetAdjuster(weight: 1.6),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 73109.0
        )
    }
}
