import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual panel allocation calculation.
    protocol ManualPanelAllocationAdjuster {
        func describe() -> String
        func adjust(_ item: ManualPanelAllocation, value: Double) -> Double
    }

    final class SourceManualPanelAllocationAdjuster: ManualPanelAllocationAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ManualPanelAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualPanelAllocationAdjuster: ManualPanelAllocationAdjuster {
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

        func adjust(_ item: ManualPanelAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualPanelAllocationAdjuster: ManualPanelAllocationAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualPanelAllocation, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual panel allocation steps in order and keeps a trace of each.
    final class ManualPanelAllocationEngine {
        var steps: [any ManualPanelAllocationAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualPanelAllocationAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualPanelAllocation) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ManualPanelAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualPanelAllocationEngine(_ flags: Kit.Flags.Registry) -> ManualPanelAllocationEngine {
        return ManualPanelAllocationEngine(
            steps: [
                SourceManualPanelAllocationAdjuster(factors: ["south": 1.01, "north": 1.12, "online": 1.19]),
                FlaggedManualPanelAllocationAdjuster(
                    flags: flags,
                    flag: "manual-panel-allocation-lenient",
                    percent: -3.0
                ),
                TieredManualPanelAllocationAdjuster(bounds: [336.0, 2642.0, 9542.0], rates: [1.0, 0.93, 0.88]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 35223.8
        )
    }
}
