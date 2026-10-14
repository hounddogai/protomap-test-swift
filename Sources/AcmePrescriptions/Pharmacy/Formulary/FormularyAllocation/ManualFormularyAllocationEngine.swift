import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual formulary allocation calculation.
    protocol ManualFormularyAllocationStep {
        func describe() -> String
        func adjust(_ item: ManualFormularyAllocation, value: Double) -> Double
    }

    final class FlaggedManualFormularyAllocationAdjuster: ManualFormularyAllocationStep {
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

        func adjust(_ item: ManualFormularyAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualFormularyAllocationAdjuster: ManualFormularyAllocationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualFormularyAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualFormularyAllocationAdjuster: ManualFormularyAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualFormularyAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual formulary allocation steps in order and keeps a trace of each.
    final class ManualFormularyAllocationEngine {
        var steps: [any ManualFormularyAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualFormularyAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualFormularyAllocation) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualFormularyAllocationStep = steps[index]
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

        func evaluateAll(_ items: [ManualFormularyAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualFormularyAllocationEngine(_ flags: Kit.Flags.Registry) -> ManualFormularyAllocationEngine {
        return ManualFormularyAllocationEngine(
            steps: [
                FlaggedManualFormularyAllocationAdjuster(
                    flags: flags,
                    flag: "manual-formulary-allocation-global",
                    percent: 0.3
                ),
                TieredManualFormularyAllocationAdjuster(
                    bounds: [2556.0, 4331.0, 5668.0, 5741.0],
                    rates: [0.87, 1.17, 0.84, 0.9]
                ),
                MinimumManualFormularyAllocationAdjuster(minimum: 9.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 2124.2
        )
    }
}
