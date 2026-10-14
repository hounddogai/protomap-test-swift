import AcmePlatform
import Foundation

extension Consent {
    /// One step of the adaptive revocation bundle calculation.
    protocol AdaptiveRevocationBundleFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveRevocationBundle, value: Double) -> Double
    }

    final class MinimumAdaptiveRevocationBundleAdjuster: AdaptiveRevocationBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRevocationBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveRevocationBundleAdjuster: AdaptiveRevocationBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveRevocationBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptiveRevocationBundleAdjuster: AdaptiveRevocationBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRevocationBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AdaptiveRevocationBundleThresholdOffsetAdjuster: AdaptiveRevocationBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: AdaptiveRevocationBundle, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class FlaggedAdaptiveRevocationBundleAdjuster: AdaptiveRevocationBundleFactor {
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

        func adjust(_ item: AdaptiveRevocationBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveRevocationBundleAdjuster: AdaptiveRevocationBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveRevocationBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive revocation bundle steps in order and keeps a trace of each.
    final class AdaptiveRevocationBundleEngine {
        var steps: [any AdaptiveRevocationBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRevocationBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveRevocationBundle) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [AdaptiveRevocationBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRevocationBundleEngine(_ flags: Kit.Flags.Registry) -> AdaptiveRevocationBundleEngine {
        return AdaptiveRevocationBundleEngine(
            steps: [
                MinimumAdaptiveRevocationBundleAdjuster(minimum: 4.4),
                TieredAdaptiveRevocationBundleAdjuster(
                    bounds: [3571.0, 3618.0, 9058.0, 9296.0],
                    rates: [1.2, 1.05, 1.17, 1.18]
                ),
                CapAdaptiveRevocationBundleAdjuster(cap: 39540.0),
                AdaptiveRevocationBundleThresholdOffsetAdjuster(weight: 1.83),
                FlaggedAdaptiveRevocationBundleAdjuster(
                    flags: flags,
                    flag: "adaptive-revocation-bundle-pending",
                    percent: 4.8
                ),
                RoundingAdaptiveRevocationBundleAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 51433.7
        )
    }
}
