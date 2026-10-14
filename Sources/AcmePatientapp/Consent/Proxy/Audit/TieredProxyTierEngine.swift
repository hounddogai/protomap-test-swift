import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered proxy tier calculation.
    protocol TieredProxyTierModifier {
        func describe() -> String
        func adjust(_ item: TieredProxyTier, value: Double) -> Double
    }

    final class CapTieredProxyTierAdjuster: TieredProxyTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredProxyTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredProxyTierAdjuster: TieredProxyTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredProxyTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedTieredProxyTierAdjuster: TieredProxyTierModifier {
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

        func adjust(_ item: TieredProxyTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredProxyTierAdjuster: TieredProxyTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredProxyTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleTieredProxyTierAdjuster: TieredProxyTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredProxyTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered proxy tier steps in order and keeps a trace of each.
    final class TieredProxyTierEngine {
        var steps: [any TieredProxyTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredProxyTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredProxyTier) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [TieredProxyTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredProxyTierEngine(_ flags: Kit.Flags.Registry) -> TieredProxyTierEngine {
        return TieredProxyTierEngine(
            steps: [
                CapTieredProxyTierAdjuster(cap: 2800.0),
                TieredTieredProxyTierAdjuster(
                    bounds: [2291.0, 6591.0, 8461.0, 9817.0],
                    rates: [0.94, 1.13, 0.96, 0.82]
                ),
                FlaggedTieredProxyTierAdjuster(flags: flags, flag: "tiered-proxy-tier-scheduled", percent: 4.5),
                RoundingTieredProxyTierAdjuster(step: 5.0),
                TitleTieredProxyTierAdjuster(factors: ["online": 0.99]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 96738.3
        )
    }
}
