import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the lenient acuity plan allocation calculation.
    protocol LenientAcuityPlanAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: LenientAcuityPlanAllocation, value: Double) -> Double
    }

    final class FlaggedLenientAcuityPlanAllocationAdjuster: LenientAcuityPlanAllocationAdjuster {
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

        func adjust(_ item: LenientAcuityPlanAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLenientAcuityPlanAllocationAdjuster: LenientAcuityPlanAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientAcuityPlanAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientAcuityPlanAllocationAdjuster: LenientAcuityPlanAllocationAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientAcuityPlanAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient acuity plan allocation steps in order and keeps a trace of each.
    final class LenientAcuityPlanAllocationEngine {
        var steps: [any LenientAcuityPlanAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAcuityPlanAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientAcuityPlanAllocation) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientAcuityPlanAllocationAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientAcuityPlanAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientAcuityPlanAllocationEngine(_ flags: Kit.Flags.Registry) -> LenientAcuityPlanAllocationEngine {
        return LenientAcuityPlanAllocationEngine(
            steps: [
                FlaggedLenientAcuityPlanAllocationAdjuster(
                    flags: flags,
                    flag: "lenient-acuity-plan-allocation-fallback",
                    percent: 4.2
                ),
                TieredLenientAcuityPlanAllocationAdjuster(
                    bounds: [3993.0, 4524.0, 8825.0, 9173.0],
                    rates: [1.16, 1.08, 0.91, 1.04]
                ),
                CapLenientAcuityPlanAllocationAdjuster(cap: 23525.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 86158.0
        )
    }
}
