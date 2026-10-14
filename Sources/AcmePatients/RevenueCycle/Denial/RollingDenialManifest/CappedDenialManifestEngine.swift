import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped denial manifest calculation.
    protocol CappedDenialManifestStep {
        func describe() -> String
        func adjust(_ item: CappedDenialManifest, value: Double) -> Double
    }

    final class TieredCappedDenialManifestAdjuster: CappedDenialManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedDenialManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCappedDenialManifestAdjuster: CappedDenialManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedDenialManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCappedDenialManifestAdjuster: CappedDenialManifestStep {
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

        func adjust(_ item: CappedDenialManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelCappedDenialManifestAdjuster: CappedDenialManifestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: CappedDenialManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedDenialManifestQuantityOffsetAdjuster: CappedDenialManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CappedDenialManifest, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapCappedDenialManifestAdjuster: CappedDenialManifestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedDenialManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the capped denial manifest steps in order and keeps a trace of each.
    final class CappedDenialManifestEngine {
        var steps: [any CappedDenialManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedDenialManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedDenialManifest) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [CappedDenialManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedDenialManifestEngine(_ flags: Kit.Flags.Registry) -> CappedDenialManifestEngine {
        return CappedDenialManifestEngine(
            steps: [
                TieredCappedDenialManifestAdjuster(bounds: [380.0, 3556.0, 9670.0], rates: [1.02, 0.91, 0.9]),
                PercentCappedDenialManifestAdjuster(percent: 21.1),
                FlaggedCappedDenialManifestAdjuster(
                    flags: flags,
                    flag: "capped-denial-manifest-regional",
                    percent: -5.3
                ),
                ChannelCappedDenialManifestAdjuster(factors: ["retail": 1.08, "north": 1.4]),
                CappedDenialManifestQuantityOffsetAdjuster(weight: 0.81),
                CapCappedDenialManifestAdjuster(cap: 14341.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 88818.7
        )
    }
}
