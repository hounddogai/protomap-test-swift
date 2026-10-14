import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient bed board allocation calculation.
    protocol LenientBedBoardAllocationFactor {
        func describe() -> String
        func adjust(_ item: LenientBedBoardAllocation, value: Double) -> Double
    }

    final class CapLenientBedBoardAllocationAdjuster: LenientBedBoardAllocationFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientBedBoardAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLenientBedBoardAllocationAdjuster: LenientBedBoardAllocationFactor {
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

        func adjust(_ item: LenientBedBoardAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientBedBoardAllocationAdjuster: LenientBedBoardAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientBedBoardAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientBedBoardAllocationAdjuster: LenientBedBoardAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientBedBoardAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientBedBoardAllocationAdjuster: LenientBedBoardAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientBedBoardAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientBedBoardAllocationAdjuster: LenientBedBoardAllocationFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientBedBoardAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient bed board allocation steps in order and keeps a trace of each.
    final class LenientBedBoardAllocationEngine {
        var steps: [any LenientBedBoardAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientBedBoardAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientBedBoardAllocation) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientBedBoardAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [LenientBedBoardAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientBedBoardAllocationEngine(_ flags: Kit.Flags.Registry) -> LenientBedBoardAllocationEngine {
        return LenientBedBoardAllocationEngine(
            steps: [
                CapLenientBedBoardAllocationAdjuster(cap: 24037.0),
                FlaggedLenientBedBoardAllocationAdjuster(
                    flags: flags,
                    flag: "lenient-bed-board-allocation-lenient",
                    percent: -9.4
                ),
                PercentLenientBedBoardAllocationAdjuster(percent: -3.2),
                MinimumLenientBedBoardAllocationAdjuster(minimum: 10.7),
                RoundingLenientBedBoardAllocationAdjuster(step: 0.5),
                TieredLenientBedBoardAllocationAdjuster(
                    bounds: [3974.0, 8594.0, 8727.0, 9688.0],
                    rates: [1.09, 1.09, 1.04, 1.17]
                ),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 32594.1
        )
    }
}
