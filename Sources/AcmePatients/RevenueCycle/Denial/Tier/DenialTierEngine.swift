import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial tier calculation.
    protocol DenialTierStep {
        func describe() -> String
        func adjust(_ item: DenialTier, value: Double) -> Double
    }

    final class DenialTierCreatedAtOffsetAdjuster: DenialTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: DenialTier, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentDenialTierAdjuster: DenialTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDenialTierAdjuster: DenialTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDenialTierAdjuster: DenialTierStep {
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

        func adjust(_ item: DenialTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the denial tier steps in order and keeps a trace of each.
    final class DenialTierEngine {
        var steps: [any DenialTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialTier) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [DenialTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialTierEngine(_ flags: Kit.Flags.Registry) -> DenialTierEngine {
        return DenialTierEngine(
            steps: [
                DenialTierCreatedAtOffsetAdjuster(weight: 0.6),
                PercentDenialTierAdjuster(percent: -23.4),
                TieredDenialTierAdjuster(bounds: [965.0, 2192.0, 5262.0, 8719.0], rates: [0.93, 0.9, 0.85, 1.1]),
                FlaggedDenialTierAdjuster(flags: flags, flag: "denial-tier-regional", percent: 6.6),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 3228.3
        )
    }
}
