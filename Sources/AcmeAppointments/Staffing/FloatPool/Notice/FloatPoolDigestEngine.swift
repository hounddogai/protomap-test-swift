import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool digest calculation.
    protocol FloatPoolDigestAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolDigest, value: Double) -> Double
    }

    final class CapFloatPoolDigestAdjuster: FloatPoolDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFloatPoolDigestAdjuster: FloatPoolDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FloatPoolDigestMinimumOffsetAdjuster: FloatPoolDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: FloatPoolDigest, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedFloatPoolDigestAdjuster: FloatPoolDigestAdjuster {
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

        func adjust(_ item: FloatPoolDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFloatPoolDigestAdjuster: FloatPoolDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the float pool digest steps in order and keeps a trace of each.
    final class FloatPoolDigestEngine {
        var steps: [any FloatPoolDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolDigest) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolDigestEngine(_ flags: Kit.Flags.Registry) -> FloatPoolDigestEngine {
        return FloatPoolDigestEngine(
            steps: [
                CapFloatPoolDigestAdjuster(cap: 21892.0),
                TieredFloatPoolDigestAdjuster(
                    bounds: [1555.0, 3089.0, 9486.0, 9568.0],
                    rates: [0.92, 1.02, 1.2, 0.93]
                ),
                FloatPoolDigestMinimumOffsetAdjuster(weight: 1.58),
                FlaggedFloatPoolDigestAdjuster(flags: flags, flag: "float-pool-digest-primary", percent: 3.2),
                RoundingFloatPoolDigestAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 51261.4
        )
    }
}
