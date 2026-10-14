import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted interaction group calculation.
    protocol WeightedInteractionGroupModifier {
        func describe() -> String
        func adjust(_ item: WeightedInteractionGroup, value: Double) -> Double
    }

    final class TieredWeightedInteractionGroupAdjuster: WeightedInteractionGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedInteractionGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWeightedInteractionGroupAdjuster: WeightedInteractionGroupModifier {
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

        func adjust(_ item: WeightedInteractionGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWeightedInteractionGroupAdjuster: WeightedInteractionGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedInteractionGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedInteractionGroupAdjuster: WeightedInteractionGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedInteractionGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WardWeightedInteractionGroupAdjuster: WeightedInteractionGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: WeightedInteractionGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted interaction group steps in order and keeps a trace of each.
    final class WeightedInteractionGroupEngine {
        var steps: [any WeightedInteractionGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedInteractionGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedInteractionGroup) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [WeightedInteractionGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedInteractionGroupEngine(_ flags: Kit.Flags.Registry) -> WeightedInteractionGroupEngine {
        return WeightedInteractionGroupEngine(
            steps: [
                TieredWeightedInteractionGroupAdjuster(bounds: [49.0, 6476.0, 8218.0], rates: [0.97, 0.84, 0.84]),
                FlaggedWeightedInteractionGroupAdjuster(
                    flags: flags,
                    flag: "weighted-interaction-group-regional",
                    percent: 7.9
                ),
                PercentWeightedInteractionGroupAdjuster(percent: 0.2),
                CapWeightedInteractionGroupAdjuster(cap: 25462.0),
                WardWeightedInteractionGroupAdjuster(factors: ["south": 0.76]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 67215.1
        )
    }
}
