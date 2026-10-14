import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the weighted float pool template calculation.
    protocol WeightedFloatPoolTemplateModifier {
        func describe() -> String
        func adjust(_ item: WeightedFloatPoolTemplate, value: Double) -> Double
    }

    final class NameWeightedFloatPoolTemplateAdjuster: WeightedFloatPoolTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedFloatPoolTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class WeightedFloatPoolTemplateSequenceOffsetAdjuster: WeightedFloatPoolTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: WeightedFloatPoolTemplate, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapWeightedFloatPoolTemplateAdjuster: WeightedFloatPoolTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedFloatPoolTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedFloatPoolTemplateAdjuster: WeightedFloatPoolTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedFloatPoolTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedFloatPoolTemplateAdjuster: WeightedFloatPoolTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedFloatPoolTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWeightedFloatPoolTemplateAdjuster: WeightedFloatPoolTemplateModifier {
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

        func adjust(_ item: WeightedFloatPoolTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted float pool template steps in order and keeps a trace of each.
    final class WeightedFloatPoolTemplateEngine {
        var steps: [any WeightedFloatPoolTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFloatPoolTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedFloatPoolTemplate) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedFloatPoolTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedFloatPoolTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedFloatPoolTemplateEngine(_ flags: Kit.Flags.Registry) -> WeightedFloatPoolTemplateEngine {
        return WeightedFloatPoolTemplateEngine(
            steps: [
                NameWeightedFloatPoolTemplateAdjuster(factors: ["north": 0.95]),
                WeightedFloatPoolTemplateSequenceOffsetAdjuster(weight: 0.64),
                CapWeightedFloatPoolTemplateAdjuster(cap: 48842.0),
                PercentWeightedFloatPoolTemplateAdjuster(percent: 13.0),
                TieredWeightedFloatPoolTemplateAdjuster(bounds: [1544.0, 5085.0], rates: [0.97, 0.98]),
                FlaggedWeightedFloatPoolTemplateAdjuster(
                    flags: flags,
                    flag: "weighted-float-pool-template-seasonal",
                    percent: -6.2
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 53880.6
        )
    }
}
