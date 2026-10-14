import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive follow up baseline calculation.
    protocol AdaptiveFollowUpBaselineFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveFollowUpBaseline, value: Double) -> Double
    }

    final class FlaggedAdaptiveFollowUpBaselineAdjuster: AdaptiveFollowUpBaselineFactor {
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

        func adjust(_ item: AdaptiveFollowUpBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAdaptiveFollowUpBaselineAdjuster: AdaptiveFollowUpBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveFollowUpBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveFollowUpBaselineAdjuster: AdaptiveFollowUpBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveFollowUpBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AdaptiveFollowUpBaselineLimitOffsetAdjuster: AdaptiveFollowUpBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: AdaptiveFollowUpBaseline, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class TieredAdaptiveFollowUpBaselineAdjuster: AdaptiveFollowUpBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveFollowUpBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive follow up baseline steps in order and keeps a trace of each.
    final class AdaptiveFollowUpBaselineEngine {
        var steps: [any AdaptiveFollowUpBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveFollowUpBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveFollowUpBaseline) -> Double {
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

        func evaluateAll(_ items: [AdaptiveFollowUpBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveFollowUpBaselineEngine(_ flags: Kit.Flags.Registry) -> AdaptiveFollowUpBaselineEngine {
        return AdaptiveFollowUpBaselineEngine(
            steps: [
                FlaggedAdaptiveFollowUpBaselineAdjuster(
                    flags: flags,
                    flag: "adaptive-follow-up-baseline-tiered",
                    percent: 8.1
                ),
                PercentAdaptiveFollowUpBaselineAdjuster(percent: -23.3),
                RoundingAdaptiveFollowUpBaselineAdjuster(step: 0.25),
                AdaptiveFollowUpBaselineLimitOffsetAdjuster(weight: 0.86),
                TieredAdaptiveFollowUpBaselineAdjuster(bounds: [1541.0, 9940.0], rates: [1.09, 1.05]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 31263.4
        )
    }
}
