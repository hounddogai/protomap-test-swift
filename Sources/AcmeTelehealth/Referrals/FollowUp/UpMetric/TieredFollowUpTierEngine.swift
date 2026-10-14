import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered follow up tier calculation.
    protocol TieredFollowUpTierAdjuster {
        func describe() -> String
        func adjust(_ item: TieredFollowUpTier, value: Double) -> Double
    }

    final class CapTieredFollowUpTierAdjuster: TieredFollowUpTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredFollowUpTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredFollowUpTierAdjuster: TieredFollowUpTierAdjuster {
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

        func adjust(_ item: TieredFollowUpTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredFollowUpTierAdjuster: TieredFollowUpTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredFollowUpTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumTieredFollowUpTierAdjuster: TieredFollowUpTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredFollowUpTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered follow up tier steps in order and keeps a trace of each.
    final class TieredFollowUpTierEngine {
        var steps: [any TieredFollowUpTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredFollowUpTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredFollowUpTier) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredFollowUpTierAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [TieredFollowUpTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredFollowUpTierEngine(_ flags: Kit.Flags.Registry) -> TieredFollowUpTierEngine {
        return TieredFollowUpTierEngine(
            steps: [
                CapTieredFollowUpTierAdjuster(cap: 3776.0),
                FlaggedTieredFollowUpTierAdjuster(flags: flags, flag: "tiered-follow-up-tier-seasonal", percent: -6.3),
                TieredTieredFollowUpTierAdjuster(bounds: [3622.0, 4851.0, 7408.0], rates: [1.05, 1.15, 1.16]),
                MinimumTieredFollowUpTierAdjuster(minimum: 22.9),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 67003.1
        )
    }
}
