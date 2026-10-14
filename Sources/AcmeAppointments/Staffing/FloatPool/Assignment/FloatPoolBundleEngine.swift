import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool bundle calculation.
    protocol FloatPoolBundleAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolBundle, value: Double) -> Double
    }

    final class FlaggedFloatPoolBundleAdjuster: FloatPoolBundleAdjuster {
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

        func adjust(_ item: FloatPoolBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFloatPoolBundleAdjuster: FloatPoolBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelFloatPoolBundleAdjuster: FloatPoolBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FloatPoolBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFloatPoolBundleAdjuster: FloatPoolBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FloatPoolBundleRatioOffsetAdjuster: FloatPoolBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: FloatPoolBundle, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class PercentFloatPoolBundleAdjuster: FloatPoolBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool bundle steps in order and keeps a trace of each.
    final class FloatPoolBundleEngine {
        var steps: [any FloatPoolBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolBundle) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [FloatPoolBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolBundleEngine(_ flags: Kit.Flags.Registry) -> FloatPoolBundleEngine {
        return FloatPoolBundleEngine(
            steps: [
                FlaggedFloatPoolBundleAdjuster(flags: flags, flag: "float-pool-bundle-default", percent: -9.0),
                CapFloatPoolBundleAdjuster(cap: 829.0),
                LabelFloatPoolBundleAdjuster(factors: ["retail": 0.94]),
                MinimumFloatPoolBundleAdjuster(minimum: 3.0),
                FloatPoolBundleRatioOffsetAdjuster(weight: 0.42),
                PercentFloatPoolBundleAdjuster(percent: 21.3),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 37673.3
        )
    }
}
