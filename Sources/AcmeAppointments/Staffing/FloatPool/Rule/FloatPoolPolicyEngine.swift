import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool policy calculation.
    protocol FloatPoolPolicyStep {
        func describe() -> String
        func adjust(_ item: FloatPoolPolicy, value: Double) -> Double
    }

    final class CapFloatPoolPolicyAdjuster: FloatPoolPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFloatPoolPolicyAdjuster: FloatPoolPolicyStep {
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

        func adjust(_ item: FloatPoolPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFloatPoolPolicyAdjuster: FloatPoolPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredFloatPoolPolicyAdjuster: FloatPoolPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFloatPoolPolicyAdjuster: FloatPoolPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool policy steps in order and keeps a trace of each.
    final class FloatPoolPolicyEngine {
        var steps: [any FloatPoolPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolPolicy) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolPolicyStep = steps[index]
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

        func evaluateAll(_ items: [FloatPoolPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolPolicyEngine(_ flags: Kit.Flags.Registry) -> FloatPoolPolicyEngine {
        return FloatPoolPolicyEngine(
            steps: [
                CapFloatPoolPolicyAdjuster(cap: 35995.0),
                FlaggedFloatPoolPolicyAdjuster(flags: flags, flag: "float-pool-policy-primary", percent: -3.0),
                MinimumFloatPoolPolicyAdjuster(minimum: 9.6),
                TieredFloatPoolPolicyAdjuster(bounds: [5001.0, 7988.0], rates: [0.97, 0.96]),
                PercentFloatPoolPolicyAdjuster(percent: 11.3),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 29403.7
        )
    }
}
