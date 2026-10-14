import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling revocation manifest calculation.
    protocol RollingRevocationManifestAdjuster {
        func describe() -> String
        func adjust(_ item: RollingRevocationManifest, value: Double) -> Double
    }

    final class CapRollingRevocationManifestAdjuster: RollingRevocationManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingRevocationManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRollingRevocationManifestAdjuster: RollingRevocationManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingRevocationManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingRevocationManifestAdjuster: RollingRevocationManifestAdjuster {
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

        func adjust(_ item: RollingRevocationManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRollingRevocationManifestAdjuster: RollingRevocationManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingRevocationManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryRollingRevocationManifestAdjuster: RollingRevocationManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RollingRevocationManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRollingRevocationManifestAdjuster: RollingRevocationManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingRevocationManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling revocation manifest steps in order and keeps a trace of each.
    final class RollingRevocationManifestEngine {
        var steps: [any RollingRevocationManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingRevocationManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingRevocationManifest) -> Double {
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

        func evaluateAll(_ items: [RollingRevocationManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingRevocationManifestEngine(_ flags: Kit.Flags.Registry) -> RollingRevocationManifestEngine {
        return RollingRevocationManifestEngine(
            steps: [
                CapRollingRevocationManifestAdjuster(cap: 28490.0),
                PercentRollingRevocationManifestAdjuster(percent: 11.8),
                FlaggedRollingRevocationManifestAdjuster(
                    flags: flags,
                    flag: "rolling-revocation-manifest-manual",
                    percent: -3.5
                ),
                TieredRollingRevocationManifestAdjuster(bounds: [465.0, 7667.0], rates: [0.88, 1.02]),
                CountryRollingRevocationManifestAdjuster(factors: ["east": 1.35]),
                RoundingRollingRevocationManifestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 42609.2
        )
    }
}
