import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool manifest calculation.
    protocol FloatPoolManifestAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolManifest, value: Double) -> Double
    }

    final class FacilityFloatPoolManifestAdjuster: FloatPoolManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FloatPoolManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFloatPoolManifestAdjuster: FloatPoolManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FloatPoolManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingFloatPoolManifestAdjuster: FloatPoolManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFloatPoolManifestAdjuster: FloatPoolManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFloatPoolManifestAdjuster: FloatPoolManifestAdjuster {
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

        func adjust(_ item: FloatPoolManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFloatPoolManifestAdjuster: FloatPoolManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FloatPoolManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the float pool manifest steps in order and keeps a trace of each.
    final class FloatPoolManifestEngine {
        var steps: [any FloatPoolManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FloatPoolManifest) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolManifestAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFloatPoolManifestEngine(_ flags: Kit.Flags.Registry) -> FloatPoolManifestEngine {
        return FloatPoolManifestEngine(
            steps: [
                FacilityFloatPoolManifestAdjuster(factors: ["retail": 0.78, "central": 1.33]),
                TieredFloatPoolManifestAdjuster(
                    bounds: [2980.0, 2994.0, 6322.0, 7205.0],
                    rates: [0.96, 0.97, 1.12, 0.92]
                ),
                RoundingFloatPoolManifestAdjuster(step: 0.1),
                CapFloatPoolManifestAdjuster(cap: 41100.0),
                FlaggedFloatPoolManifestAdjuster(flags: flags, flag: "float-pool-manifest-weighted", percent: -1.0),
                PercentFloatPoolManifestAdjuster(percent: 19.9),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 34584.8
        )
    }
}
