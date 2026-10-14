import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending rounding tier calculation.
    protocol PendingRoundingTierAdjuster {
        func describe() -> String
        func adjust(_ item: PendingRoundingTier, value: Double) -> Double
    }

    final class PendingRoundingTierGraceDaysOffsetAdjuster: PendingRoundingTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: PendingRoundingTier, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingPendingRoundingTierAdjuster: PendingRoundingTierAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingRoundingTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPendingRoundingTierAdjuster: PendingRoundingTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingRoundingTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPendingRoundingTierAdjuster: PendingRoundingTierAdjuster {
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

        func adjust(_ item: PendingRoundingTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingRoundingTierAdjuster: PendingRoundingTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingRoundingTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending rounding tier steps in order and keeps a trace of each.
    final class PendingRoundingTierEngine {
        var steps: [any PendingRoundingTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRoundingTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingRoundingTier) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingRoundingTierAdjuster = steps[index]
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

        func evaluateAll(_ items: [PendingRoundingTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingRoundingTierEngine(_ flags: Kit.Flags.Registry) -> PendingRoundingTierEngine {
        return PendingRoundingTierEngine(
            steps: [
                PendingRoundingTierGraceDaysOffsetAdjuster(weight: 0.18),
                RoundingPendingRoundingTierAdjuster(step: 1.0),
                PercentPendingRoundingTierAdjuster(percent: 0.5),
                FlaggedPendingRoundingTierAdjuster(flags: flags, flag: "pending-rounding-tier-primary", percent: 2.2),
                TieredPendingRoundingTierAdjuster(
                    bounds: [3089.0, 3824.0, 6629.0, 8909.0],
                    rates: [0.92, 0.99, 1.03, 0.87]
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 70464.6
        )
    }
}
