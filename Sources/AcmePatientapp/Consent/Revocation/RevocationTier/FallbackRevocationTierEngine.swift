import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback revocation tier calculation.
    protocol FallbackRevocationTierModifier {
        func describe() -> String
        func adjust(_ item: FallbackRevocationTier, value: Double) -> Double
    }

    final class MinimumFallbackRevocationTierAdjuster: FallbackRevocationTierModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackRevocationTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackRevocationTierAdjuster: FallbackRevocationTierModifier {
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

        func adjust(_ item: FallbackRevocationTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionFallbackRevocationTierAdjuster: FallbackRevocationTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackRevocationTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FallbackRevocationTierBatchSizeOffsetAdjuster: FallbackRevocationTierModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: FallbackRevocationTier, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the fallback revocation tier steps in order and keeps a trace of each.
    final class FallbackRevocationTierEngine {
        var steps: [any FallbackRevocationTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackRevocationTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackRevocationTier) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [FallbackRevocationTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackRevocationTierEngine(_ flags: Kit.Flags.Registry) -> FallbackRevocationTierEngine {
        return FallbackRevocationTierEngine(
            steps: [
                MinimumFallbackRevocationTierAdjuster(minimum: 46.5),
                FlaggedFallbackRevocationTierAdjuster(
                    flags: flags,
                    flag: "fallback-revocation-tier-legacy",
                    percent: 6.1
                ),
                RegionFallbackRevocationTierAdjuster(factors: ["west": 1.2]),
                FallbackRevocationTierBatchSizeOffsetAdjuster(weight: 0.21),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 85328.5
        )
    }
}
