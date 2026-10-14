import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped overtime rollup calculation.
    protocol CappedOvertimeRollupAdjuster {
        func describe() -> String
        func adjust(_ item: CappedOvertimeRollup, value: Double) -> Double
    }

    final class FlaggedCappedOvertimeRollupAdjuster: CappedOvertimeRollupAdjuster {
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

        func adjust(_ item: CappedOvertimeRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedOvertimeRollupAdjuster: CappedOvertimeRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedOvertimeRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCappedOvertimeRollupAdjuster: CappedOvertimeRollupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedOvertimeRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped overtime rollup steps in order and keeps a trace of each.
    final class CappedOvertimeRollupEngine {
        var steps: [any CappedOvertimeRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedOvertimeRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedOvertimeRollup) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedOvertimeRollupAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedOvertimeRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedOvertimeRollupEngine(_ flags: Kit.Flags.Registry) -> CappedOvertimeRollupEngine {
        return CappedOvertimeRollupEngine(
            steps: [
                FlaggedCappedOvertimeRollupAdjuster(
                    flags: flags,
                    flag: "capped-overtime-rollup-rolling",
                    percent: 5.6
                ),
                RoundingCappedOvertimeRollupAdjuster(step: 5.0),
                TieredCappedOvertimeRollupAdjuster(
                    bounds: [4341.0, 4596.0, 5209.0, 5280.0],
                    rates: [0.8, 0.8, 0.86, 1.13]
                ),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 37975.2
        )
    }
}
