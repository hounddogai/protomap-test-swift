import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted formulary profile calculation.
    protocol WeightedFormularyProfileModifier {
        func describe() -> String
        func adjust(_ item: WeightedFormularyProfile, value: Double) -> Double
    }

    final class WeightedFormularyProfileRetriesOffsetAdjuster: WeightedFormularyProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: WeightedFormularyProfile, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumWeightedFormularyProfileAdjuster: WeightedFormularyProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedFormularyProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedFormularyProfileAdjuster: WeightedFormularyProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedFormularyProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedWeightedFormularyProfileAdjuster: WeightedFormularyProfileModifier {
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

        func adjust(_ item: WeightedFormularyProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWeightedFormularyProfileAdjuster: WeightedFormularyProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedFormularyProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted formulary profile steps in order and keeps a trace of each.
    final class WeightedFormularyProfileEngine {
        var steps: [any WeightedFormularyProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedFormularyProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedFormularyProfile) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [WeightedFormularyProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedFormularyProfileEngine(_ flags: Kit.Flags.Registry) -> WeightedFormularyProfileEngine {
        return WeightedFormularyProfileEngine(
            steps: [
                WeightedFormularyProfileRetriesOffsetAdjuster(weight: 0.92),
                MinimumWeightedFormularyProfileAdjuster(minimum: 33.0),
                TieredWeightedFormularyProfileAdjuster(bounds: [1046.0, 3542.0, 5952.0], rates: [1.01, 1.19, 1.13]),
                FlaggedWeightedFormularyProfileAdjuster(
                    flags: flags,
                    flag: "weighted-formulary-profile-lenient",
                    percent: -0.9
                ),
                RoundingWeightedFormularyProfileAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 13619.2
        )
    }
}
