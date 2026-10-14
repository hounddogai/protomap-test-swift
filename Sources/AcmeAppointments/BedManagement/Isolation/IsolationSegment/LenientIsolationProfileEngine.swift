import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient isolation profile calculation.
    protocol LenientIsolationProfileFactor {
        func describe() -> String
        func adjust(_ item: LenientIsolationProfile, value: Double) -> Double
    }

    final class TieredLenientIsolationProfileAdjuster: LenientIsolationProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientIsolationProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientIsolationProfileAdjuster: LenientIsolationProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientIsolationProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLenientIsolationProfileAdjuster: LenientIsolationProfileFactor {
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

        func adjust(_ item: LenientIsolationProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientIsolationProfileAdjuster: LenientIsolationProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientIsolationProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientIsolationProfileAdjuster: LenientIsolationProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientIsolationProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient isolation profile steps in order and keeps a trace of each.
    final class LenientIsolationProfileEngine {
        var steps: [any LenientIsolationProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientIsolationProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientIsolationProfile) -> Double {
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

        func evaluateAll(_ items: [LenientIsolationProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientIsolationProfileEngine(_ flags: Kit.Flags.Registry) -> LenientIsolationProfileEngine {
        return LenientIsolationProfileEngine(
            steps: [
                TieredLenientIsolationProfileAdjuster(bounds: [2521.0, 3391.0, 7733.0], rates: [1.14, 1.11, 0.95]),
                MinimumLenientIsolationProfileAdjuster(minimum: 47.0),
                FlaggedLenientIsolationProfileAdjuster(
                    flags: flags,
                    flag: "lenient-isolation-profile-adaptive",
                    percent: -9.8
                ),
                PercentLenientIsolationProfileAdjuster(percent: 5.3),
                CapLenientIsolationProfileAdjuster(cap: 47327.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 1361.4
        )
    }
}
