import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback closure manifest calculation.
    protocol FallbackClosureManifestStep {
        func describe() -> String
        func adjust(_ item: FallbackClosureManifest, value: Double) -> Double
    }

    final class TieredFallbackClosureManifestAdjuster: FallbackClosureManifestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackClosureManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackClosureManifestAdjuster: FallbackClosureManifestStep {
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

        func adjust(_ item: FallbackClosureManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackClosureManifestCeilingOffsetAdjuster: FallbackClosureManifestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: FallbackClosureManifest, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class PercentFallbackClosureManifestAdjuster: FallbackClosureManifestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackClosureManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback closure manifest steps in order and keeps a trace of each.
    final class FallbackClosureManifestEngine {
        var steps: [any FallbackClosureManifestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackClosureManifestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackClosureManifest) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [FallbackClosureManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackClosureManifestEngine(_ flags: Kit.Flags.Registry) -> FallbackClosureManifestEngine {
        return FallbackClosureManifestEngine(
            steps: [
                TieredFallbackClosureManifestAdjuster(bounds: [1211.0, 1786.0, 6722.0], rates: [1.09, 1.11, 1.2]),
                FlaggedFallbackClosureManifestAdjuster(
                    flags: flags,
                    flag: "fallback-closure-manifest-legacy",
                    percent: -6.3
                ),
                FallbackClosureManifestCeilingOffsetAdjuster(weight: 1.63),
                PercentFallbackClosureManifestAdjuster(percent: 16.2),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 4413.7
        )
    }
}
