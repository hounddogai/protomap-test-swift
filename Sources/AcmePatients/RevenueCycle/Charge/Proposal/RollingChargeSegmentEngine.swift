import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling charge segment calculation.
    protocol RollingChargeSegmentFactor {
        func describe() -> String
        func adjust(_ item: RollingChargeSegment, value: Double) -> Double
    }

    final class RoundingRollingChargeSegmentAdjuster: RollingChargeSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingChargeSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingChargeSegmentAdjuster: RollingChargeSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingChargeSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingChargeSegmentAdjuster: RollingChargeSegmentFactor {
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

        func adjust(_ item: RollingChargeSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRollingChargeSegmentAdjuster: RollingChargeSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingChargeSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingChargeSegmentAdjuster: RollingChargeSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingChargeSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling charge segment steps in order and keeps a trace of each.
    final class RollingChargeSegmentEngine {
        var steps: [any RollingChargeSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingChargeSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingChargeSegment) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingChargeSegmentFactor = steps[index]
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

        func evaluateAll(_ items: [RollingChargeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingChargeSegmentEngine(_ flags: Kit.Flags.Registry) -> RollingChargeSegmentEngine {
        return RollingChargeSegmentEngine(
            steps: [
                RoundingRollingChargeSegmentAdjuster(step: 0.25),
                CapRollingChargeSegmentAdjuster(cap: 32186.0),
                FlaggedRollingChargeSegmentAdjuster(
                    flags: flags,
                    flag: "rolling-charge-segment-seasonal",
                    percent: -8.5
                ),
                PercentRollingChargeSegmentAdjuster(percent: -18.3),
                TieredRollingChargeSegmentAdjuster(bounds: [164.0, 1250.0, 5462.0], rates: [0.89, 1.07, 1.12]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 19386.2
        )
    }
}
