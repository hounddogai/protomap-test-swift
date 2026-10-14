import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted accession variance calculation.
    protocol WeightedAccessionVarianceModifier {
        func describe() -> String
        func adjust(_ item: WeightedAccessionVariance, value: Double) -> Double
    }

    final class WeightedAccessionVarianceScoreOffsetAdjuster: WeightedAccessionVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: WeightedAccessionVariance, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumWeightedAccessionVarianceAdjuster: WeightedAccessionVarianceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedAccessionVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedAccessionVarianceAdjuster: WeightedAccessionVarianceModifier {
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

        func adjust(_ item: WeightedAccessionVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedAccessionVarianceAdjuster: WeightedAccessionVarianceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedAccessionVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedAccessionVarianceAdjuster: WeightedAccessionVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedAccessionVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted accession variance steps in order and keeps a trace of each.
    final class WeightedAccessionVarianceEngine {
        var steps: [any WeightedAccessionVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAccessionVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedAccessionVariance) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedAccessionVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedAccessionVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedAccessionVarianceEngine(_ flags: Kit.Flags.Registry) -> WeightedAccessionVarianceEngine {
        return WeightedAccessionVarianceEngine(
            steps: [
                WeightedAccessionVarianceScoreOffsetAdjuster(weight: 0.24),
                MinimumWeightedAccessionVarianceAdjuster(minimum: 47.3),
                FlaggedWeightedAccessionVarianceAdjuster(
                    flags: flags,
                    flag: "weighted-accession-variance-regional",
                    percent: 9.2
                ),
                TieredWeightedAccessionVarianceAdjuster(bounds: [855.0, 1274.0], rates: [1.02, 1.1]),
                RoundingWeightedAccessionVarianceAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 22480.9
        )
    }
}
