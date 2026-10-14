import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift allocation calculation.
    protocol ShiftAllocationFactor {
        func describe() -> String
        func adjust(_ item: ShiftAllocation, value: Double) -> Double
    }

    final class FlaggedShiftAllocationAdjuster: ShiftAllocationFactor {
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

        func adjust(_ item: ShiftAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingShiftAllocationAdjuster: ShiftAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumShiftAllocationAdjuster: ShiftAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredShiftAllocationAdjuster: ShiftAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapShiftAllocationAdjuster: ShiftAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the shift allocation steps in order and keeps a trace of each.
    final class ShiftAllocationEngine {
        var steps: [any ShiftAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftAllocation) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ShiftAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftAllocationEngine(_ flags: Kit.Flags.Registry) -> ShiftAllocationEngine {
        return ShiftAllocationEngine(
            steps: [
                FlaggedShiftAllocationAdjuster(flags: flags, flag: "shift-allocation-default", percent: -8.6),
                RoundingShiftAllocationAdjuster(step: 0.1),
                MinimumShiftAllocationAdjuster(minimum: 20.8),
                TieredShiftAllocationAdjuster(bounds: [3963.0, 7198.0], rates: [1.18, 1.04]),
                CapShiftAllocationAdjuster(cap: 34591.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 54546.1
        )
    }
}
