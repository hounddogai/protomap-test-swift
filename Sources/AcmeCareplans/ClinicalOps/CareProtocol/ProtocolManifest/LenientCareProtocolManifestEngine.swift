import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the lenient care protocol manifest calculation.
    protocol LenientCareProtocolManifestAdjuster {
        func describe() -> String
        func adjust(_ item: LenientCareProtocolManifest, value: Double) -> Double
    }

    final class FlaggedLenientCareProtocolManifestAdjuster: LenientCareProtocolManifestAdjuster {
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

        func adjust(_ item: LenientCareProtocolManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientCareProtocolManifestExpiresAtOffsetAdjuster: LenientCareProtocolManifestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: LenientCareProtocolManifest, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class PercentLenientCareProtocolManifestAdjuster: LenientCareProtocolManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientCareProtocolManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientCareProtocolManifestAdjuster: LenientCareProtocolManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientCareProtocolManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientCareProtocolManifestAdjuster: LenientCareProtocolManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientCareProtocolManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientCareProtocolManifestAdjuster: LenientCareProtocolManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientCareProtocolManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient care protocol manifest steps in order and keeps a trace of each.
    final class LenientCareProtocolManifestEngine {
        var steps: [any LenientCareProtocolManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientCareProtocolManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientCareProtocolManifest) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [LenientCareProtocolManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientCareProtocolManifestEngine(_ flags: Kit.Flags.Registry) -> LenientCareProtocolManifestEngine {
        return LenientCareProtocolManifestEngine(
            steps: [
                FlaggedLenientCareProtocolManifestAdjuster(
                    flags: flags,
                    flag: "lenient-care-protocol-manifest-default",
                    percent: 7.9
                ),
                LenientCareProtocolManifestExpiresAtOffsetAdjuster(weight: 1.63),
                PercentLenientCareProtocolManifestAdjuster(percent: 16.6),
                CapLenientCareProtocolManifestAdjuster(cap: 19198.0),
                MinimumLenientCareProtocolManifestAdjuster(minimum: 43.4),
                TieredLenientCareProtocolManifestAdjuster(bounds: [2626.0, 5971.0, 9069.0], rates: [1.09, 0.9, 0.94]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 41186.1
        )
    }
}
