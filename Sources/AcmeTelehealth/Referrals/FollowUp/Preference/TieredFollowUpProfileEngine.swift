import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered follow up profile calculation.
    protocol TieredFollowUpProfileModifier {
        func describe() -> String
        func adjust(_ item: TieredFollowUpProfile, value: Double) -> Double
    }

    final class TieredTieredFollowUpProfileAdjuster: TieredFollowUpProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredFollowUpProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TieredFollowUpProfileQuantityOffsetAdjuster: TieredFollowUpProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: TieredFollowUpProfile, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CapTieredFollowUpProfileAdjuster: TieredFollowUpProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredFollowUpProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelTieredFollowUpProfileAdjuster: TieredFollowUpProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TieredFollowUpProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedTieredFollowUpProfileAdjuster: TieredFollowUpProfileModifier {
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

        func adjust(_ item: TieredFollowUpProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTieredFollowUpProfileAdjuster: TieredFollowUpProfileModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredFollowUpProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered follow up profile steps in order and keeps a trace of each.
    final class TieredFollowUpProfileEngine {
        var steps: [any TieredFollowUpProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredFollowUpProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredFollowUpProfile) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [TieredFollowUpProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredFollowUpProfileEngine(_ flags: Kit.Flags.Registry) -> TieredFollowUpProfileEngine {
        return TieredFollowUpProfileEngine(
            steps: [
                TieredTieredFollowUpProfileAdjuster(bounds: [2015.0, 3087.0, 7181.0], rates: [1.13, 0.83, 0.85]),
                TieredFollowUpProfileQuantityOffsetAdjuster(weight: 0.2),
                CapTieredFollowUpProfileAdjuster(cap: 28488.0),
                LabelTieredFollowUpProfileAdjuster(factors: ["retail": 0.72]),
                FlaggedTieredFollowUpProfileAdjuster(
                    flags: flags,
                    flag: "tiered-follow-up-profile-scheduled",
                    percent: -2.4
                ),
                PercentTieredFollowUpProfileAdjuster(percent: 5.4),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 6154.7
        )
    }
}
