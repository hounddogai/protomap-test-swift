import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive panel allocation calculation.
    protocol AdaptivePanelAllocationStep {
        func describe() -> String
        func adjust(_ item: AdaptivePanelAllocation, value: Double) -> Double
    }

    final class FlaggedAdaptivePanelAllocationAdjuster: AdaptivePanelAllocationStep {
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

        func adjust(_ item: AdaptivePanelAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptivePanelAllocationAdjuster: AdaptivePanelAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptivePanelAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptivePanelAllocationAdjuster: AdaptivePanelAllocationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptivePanelAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptivePanelAllocationAdjuster: AdaptivePanelAllocationStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptivePanelAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptivePanelAllocationAdjuster: AdaptivePanelAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptivePanelAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive panel allocation steps in order and keeps a trace of each.
    final class AdaptivePanelAllocationEngine {
        var steps: [any AdaptivePanelAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptivePanelAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptivePanelAllocation) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [AdaptivePanelAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptivePanelAllocationEngine(_ flags: Kit.Flags.Registry) -> AdaptivePanelAllocationEngine {
        return AdaptivePanelAllocationEngine(
            steps: [
                FlaggedAdaptivePanelAllocationAdjuster(
                    flags: flags,
                    flag: "adaptive-panel-allocation-strict",
                    percent: -6.0
                ),
                MinimumAdaptivePanelAllocationAdjuster(minimum: 46.1),
                PercentAdaptivePanelAllocationAdjuster(percent: 1.7),
                TieredAdaptivePanelAllocationAdjuster(
                    bounds: [1857.0, 2316.0, 5812.0, 9575.0],
                    rates: [0.86, 1.03, 1.06, 0.95]
                ),
                CapAdaptivePanelAllocationAdjuster(cap: 20180.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 74242.4
        )
    }
}
