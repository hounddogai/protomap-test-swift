import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual network cycle calculation.
    protocol ManualNetworkCycleStep {
        func describe() -> String
        func adjust(_ item: ManualNetworkCycle, value: Double) -> Double
    }

    final class TieredManualNetworkCycleAdjuster: ManualNetworkCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualNetworkCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingManualNetworkCycleAdjuster: ManualNetworkCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualNetworkCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapManualNetworkCycleAdjuster: ManualNetworkCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualNetworkCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualNetworkCycleAdjuster: ManualNetworkCycleStep {
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

        func adjust(_ item: ManualNetworkCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualNetworkCycleAdjuster: ManualNetworkCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualNetworkCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardManualNetworkCycleAdjuster: ManualNetworkCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ManualNetworkCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual network cycle steps in order and keeps a trace of each.
    final class ManualNetworkCycleEngine {
        var steps: [any ManualNetworkCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualNetworkCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualNetworkCycle) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualNetworkCycleStep = steps[index]
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

        func evaluateAll(_ items: [ManualNetworkCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualNetworkCycleEngine(_ flags: Kit.Flags.Registry) -> ManualNetworkCycleEngine {
        return ManualNetworkCycleEngine(
            steps: [
                TieredManualNetworkCycleAdjuster(
                    bounds: [970.0, 2164.0, 3366.0, 7743.0],
                    rates: [0.98, 1.19, 1.03, 0.85]
                ),
                RoundingManualNetworkCycleAdjuster(step: 1.0),
                CapManualNetworkCycleAdjuster(cap: 13752.0),
                FlaggedManualNetworkCycleAdjuster(flags: flags, flag: "manual-network-cycle-scheduled", percent: -9.1),
                PercentManualNetworkCycleAdjuster(percent: 1.5),
                WardManualNetworkCycleAdjuster(factors: ["east": 0.84]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 44028.2
        )
    }
}
