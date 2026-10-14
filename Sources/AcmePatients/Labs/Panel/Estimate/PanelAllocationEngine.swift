import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel allocation calculation.
    protocol PanelAllocationModifier {
        func describe() -> String
        func adjust(_ item: PanelAllocation, value: Double) -> Double
    }

    final class TieredPanelAllocationAdjuster: PanelAllocationModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPanelAllocationAdjuster: PanelAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPanelAllocationAdjuster: PanelAllocationModifier {
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

        func adjust(_ item: PanelAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardPanelAllocationAdjuster: PanelAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: PanelAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPanelAllocationAdjuster: PanelAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPanelAllocationAdjuster: PanelAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the panel allocation steps in order and keeps a trace of each.
    final class PanelAllocationEngine {
        var steps: [any PanelAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelAllocation) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [PanelAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelAllocationEngine(_ flags: Kit.Flags.Registry) -> PanelAllocationEngine {
        return PanelAllocationEngine(
            steps: [
                TieredPanelAllocationAdjuster(bounds: [3300.0, 3783.0, 5186.0], rates: [0.84, 0.81, 0.81]),
                CapPanelAllocationAdjuster(cap: 16842.0),
                FlaggedPanelAllocationAdjuster(flags: flags, flag: "panel-allocation-pending", percent: 4.0),
                WardPanelAllocationAdjuster(factors: ["north": 1.26, "south": 0.76]),
                PercentPanelAllocationAdjuster(percent: 3.8),
                MinimumPanelAllocationAdjuster(minimum: 18.6),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 3295.0
        )
    }
}
