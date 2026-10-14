import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted dispense mapping calculation.
    protocol WeightedDispenseMappingModifier {
        func describe() -> String
        func adjust(_ item: WeightedDispenseMapping, value: Double) -> Double
    }

    final class CapWeightedDispenseMappingAdjuster: WeightedDispenseMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedDispenseMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedDispenseMappingAdjuster: WeightedDispenseMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedDispenseMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedDispenseMappingAdjuster: WeightedDispenseMappingModifier {
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

        func adjust(_ item: WeightedDispenseMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedDispenseMappingAdjuster: WeightedDispenseMappingModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedDispenseMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class WeightedDispenseMappingCapacityOffsetAdjuster: WeightedDispenseMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: WeightedDispenseMapping, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumWeightedDispenseMappingAdjuster: WeightedDispenseMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedDispenseMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the weighted dispense mapping steps in order and keeps a trace of each.
    final class WeightedDispenseMappingEngine {
        var steps: [any WeightedDispenseMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedDispenseMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedDispenseMapping) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedDispenseMappingModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedDispenseMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedDispenseMappingEngine(_ flags: Kit.Flags.Registry) -> WeightedDispenseMappingEngine {
        return WeightedDispenseMappingEngine(
            steps: [
                CapWeightedDispenseMappingAdjuster(cap: 21552.0),
                RoundingWeightedDispenseMappingAdjuster(step: 0.25),
                FlaggedWeightedDispenseMappingAdjuster(
                    flags: flags,
                    flag: "weighted-dispense-mapping-scheduled",
                    percent: 7.1
                ),
                TieredWeightedDispenseMappingAdjuster(bounds: [338.0, 6602.0], rates: [1.05, 1.15]),
                WeightedDispenseMappingCapacityOffsetAdjuster(weight: 0.21),
                MinimumWeightedDispenseMappingAdjuster(minimum: 40.9),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 89897.9
        )
    }
}
