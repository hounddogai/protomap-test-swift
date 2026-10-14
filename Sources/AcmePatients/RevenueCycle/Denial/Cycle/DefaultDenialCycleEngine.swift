import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default denial cycle calculation.
    protocol DefaultDenialCycleFactor {
        func describe() -> String
        func adjust(_ item: DefaultDenialCycle, value: Double) -> Double
    }

    final class FlaggedDefaultDenialCycleAdjuster: DefaultDenialCycleFactor {
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

        func adjust(_ item: DefaultDenialCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultDenialCycleAdjuster: DefaultDenialCycleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultDenialCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDefaultDenialCycleAdjuster: DefaultDenialCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultDenialCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default denial cycle steps in order and keeps a trace of each.
    final class DefaultDenialCycleEngineExtra {
        var steps: [any DefaultDenialCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDenialCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultDenialCycle) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DefaultDenialCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultDenialCycleEngine(_ flags: Kit.Flags.Registry) -> DefaultDenialCycleEngineExtra {
        return DefaultDenialCycleEngineExtra(
            steps: [
                FlaggedDefaultDenialCycleAdjuster(flags: flags, flag: "default-denial-cycle-capped", percent: 9.2),
                RoundingDefaultDenialCycleAdjuster(step: 0.1),
                TieredDefaultDenialCycleAdjuster(
                    bounds: [3394.0, 6123.0, 7001.0, 7949.0],
                    rates: [1.0, 0.98, 1.14, 1.08]
                ),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 71208.3
        )
    }
}
