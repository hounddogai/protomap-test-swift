import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted formulary rollup calculation.
    protocol WeightedFormularyRollupStep {
        func describe() -> String
        func adjust(_ item: WeightedFormularyRollup, value: Double) -> Double
    }

    final class NameWeightedFormularyRollupAdjuster: WeightedFormularyRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedFormularyRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class WeightedFormularyRollupGraceDaysOffsetAdjuster: WeightedFormularyRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: WeightedFormularyRollup, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapWeightedFormularyRollupAdjuster: WeightedFormularyRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedFormularyRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWeightedFormularyRollupAdjuster: WeightedFormularyRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedFormularyRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedFormularyRollupAdjuster: WeightedFormularyRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedFormularyRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedFormularyRollupAdjuster: WeightedFormularyRollupStep {
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

        func adjust(_ item: WeightedFormularyRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted formulary rollup steps in order and keeps a trace of each.
    final class WeightedFormularyRollupEngine {
        var steps: [any WeightedFormularyRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFormularyRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedFormularyRollup) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [WeightedFormularyRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedFormularyRollupEngine(_ flags: Kit.Flags.Registry) -> WeightedFormularyRollupEngine {
        return WeightedFormularyRollupEngine(
            steps: [
                NameWeightedFormularyRollupAdjuster(factors: ["online": 0.97, "south": 0.84]),
                WeightedFormularyRollupGraceDaysOffsetAdjuster(weight: 0.79),
                CapWeightedFormularyRollupAdjuster(cap: 39796.0),
                PercentWeightedFormularyRollupAdjuster(percent: 14.5),
                MinimumWeightedFormularyRollupAdjuster(minimum: 23.1),
                FlaggedWeightedFormularyRollupAdjuster(
                    flags: flags,
                    flag: "weighted-formulary-rollup-primary",
                    percent: -4.9
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 52856.4
        )
    }
}
