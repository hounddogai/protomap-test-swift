import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted formulary group calculation.
    protocol WeightedFormularyGroupModifier {
        func describe() -> String
        func adjust(_ item: WeightedFormularyGroup, value: Double) -> Double
    }

    final class WeightedFormularyGroupCreatedAtOffsetAdjuster: WeightedFormularyGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: WeightedFormularyGroup, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FlaggedWeightedFormularyGroupAdjuster: WeightedFormularyGroupModifier {
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

        func adjust(_ item: WeightedFormularyGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelWeightedFormularyGroupAdjuster: WeightedFormularyGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: WeightedFormularyGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedFormularyGroupAdjuster: WeightedFormularyGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedFormularyGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedFormularyGroupAdjuster: WeightedFormularyGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedFormularyGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedFormularyGroupAdjuster: WeightedFormularyGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedFormularyGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted formulary group steps in order and keeps a trace of each.
    final class WeightedFormularyGroupEngine {
        var steps: [any WeightedFormularyGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFormularyGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedFormularyGroup) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [WeightedFormularyGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedFormularyGroupEngine(_ flags: Kit.Flags.Registry) -> WeightedFormularyGroupEngine {
        return WeightedFormularyGroupEngine(
            steps: [
                WeightedFormularyGroupCreatedAtOffsetAdjuster(weight: 1.14),
                FlaggedWeightedFormularyGroupAdjuster(
                    flags: flags,
                    flag: "weighted-formulary-group-rolling",
                    percent: -7.8
                ),
                LabelWeightedFormularyGroupAdjuster(factors: ["east": 1.21, "west": 1.17]),
                CapWeightedFormularyGroupAdjuster(cap: 2634.0),
                TieredWeightedFormularyGroupAdjuster(bounds: [1915.0, 5474.0], rates: [0.96, 1.18]),
                MinimumWeightedFormularyGroupAdjuster(minimum: 39.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 17711.0
        )
    }
}
