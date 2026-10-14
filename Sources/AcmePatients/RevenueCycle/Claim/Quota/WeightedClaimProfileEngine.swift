import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the weighted claim profile calculation.
    protocol WeightedClaimProfileStep {
        func describe() -> String
        func adjust(_ item: WeightedClaimProfile, value: Double) -> Double
    }

    final class FlaggedWeightedClaimProfileAdjuster: WeightedClaimProfileStep {
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

        func adjust(_ item: WeightedClaimProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWeightedClaimProfileAdjuster: WeightedClaimProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedClaimProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedClaimProfileAdjuster: WeightedClaimProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedClaimProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelWeightedClaimProfileAdjuster: WeightedClaimProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedClaimProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedClaimProfileAdjuster: WeightedClaimProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedClaimProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedClaimProfileAdjuster: WeightedClaimProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedClaimProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted claim profile steps in order and keeps a trace of each.
    final class WeightedClaimProfileEngine {
        var steps: [any WeightedClaimProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedClaimProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedClaimProfile) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedClaimProfileStep = steps[index]
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

        func evaluateAll(_ items: [WeightedClaimProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedClaimProfileEngine(_ flags: Kit.Flags.Registry) -> WeightedClaimProfileEngine {
        return WeightedClaimProfileEngine(
            steps: [
                FlaggedWeightedClaimProfileAdjuster(flags: flags, flag: "weighted-claim-profile-global", percent: 2.5),
                PercentWeightedClaimProfileAdjuster(percent: 5.3),
                TieredWeightedClaimProfileAdjuster(
                    bounds: [2151.0, 2598.0, 3150.0, 6093.0],
                    rates: [0.83, 0.82, 0.96, 1.04]
                ),
                LabelWeightedClaimProfileAdjuster(factors: ["north": 0.99]),
                CapWeightedClaimProfileAdjuster(cap: 2377.0),
                RoundingWeightedClaimProfileAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 46743.0
        )
    }
}
