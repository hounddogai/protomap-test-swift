import AcmePlatform
import Foundation

extension Consent {
    /// One step of the legacy revocation manifest calculation.
    protocol LegacyRevocationManifestFactor {
        func describe() -> String
        func adjust(_ item: LegacyRevocationManifest, value: Double) -> Double
    }

    final class MinimumLegacyRevocationManifestAdjuster: LegacyRevocationManifestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyRevocationManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyRevocationManifestAdjuster: LegacyRevocationManifestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyRevocationManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyRevocationManifestAdjuster: LegacyRevocationManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyRevocationManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyRevocationManifestRetriesOffsetAdjuster: LegacyRevocationManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: LegacyRevocationManifest, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class TieredLegacyRevocationManifestAdjuster: LegacyRevocationManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyRevocationManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLegacyRevocationManifestAdjuster: LegacyRevocationManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyRevocationManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy revocation manifest steps in order and keeps a trace of each.
    final class LegacyRevocationManifestEngine {
        var steps: [any LegacyRevocationManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyRevocationManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyRevocationManifest) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [LegacyRevocationManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyRevocationManifestEngine() -> LegacyRevocationManifestEngine {
        return LegacyRevocationManifestEngine(
            steps: [
                MinimumLegacyRevocationManifestAdjuster(minimum: 20.2),
                PercentLegacyRevocationManifestAdjuster(percent: 16.8),
                CapLegacyRevocationManifestAdjuster(cap: 40799.0),
                LegacyRevocationManifestRetriesOffsetAdjuster(weight: 0.24),
                TieredLegacyRevocationManifestAdjuster(bounds: [730.0, 2834.0], rates: [0.93, 0.91]),
                RoundingLegacyRevocationManifestAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 26739.6
        )
    }
}
