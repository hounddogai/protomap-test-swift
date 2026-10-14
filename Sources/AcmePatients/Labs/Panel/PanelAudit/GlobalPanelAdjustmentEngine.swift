import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global panel adjustment calculation.
    protocol GlobalPanelAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: GlobalPanelAdjustment, value: Double) -> Double
    }

    final class CapGlobalPanelAdjustmentAdjuster: GlobalPanelAdjustmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalPanelAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGlobalPanelAdjustmentAdjuster: GlobalPanelAdjustmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalPanelAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalPanelAdjustmentAdjuster: GlobalPanelAdjustmentFactor {
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

        func adjust(_ item: GlobalPanelAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalPanelAdjustmentAdjuster: GlobalPanelAdjustmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalPanelAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global panel adjustment steps in order and keeps a trace of each.
    final class GlobalPanelAdjustmentEngine {
        var steps: [any GlobalPanelAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalPanelAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalPanelAdjustment) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [GlobalPanelAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalPanelAdjustmentEngine(_ flags: Kit.Flags.Registry) -> GlobalPanelAdjustmentEngine {
        return GlobalPanelAdjustmentEngine(
            steps: [
                CapGlobalPanelAdjustmentAdjuster(cap: 35217.0),
                TieredGlobalPanelAdjustmentAdjuster(bounds: [4669.0, 5743.0], rates: [1.17, 0.97]),
                FlaggedGlobalPanelAdjustmentAdjuster(
                    flags: flags,
                    flag: "global-panel-adjustment-seasonal",
                    percent: -1.0
                ),
                RoundingGlobalPanelAdjustmentAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 31001.2
        )
    }
}
