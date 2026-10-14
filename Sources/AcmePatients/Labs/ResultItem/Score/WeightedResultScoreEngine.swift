import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted result score calculation.
    protocol WeightedResultScoreStep {
        func describe() -> String
        func adjust(_ item: WeightedResultScore, value: Double) -> Double
    }

    final class PercentWeightedResultScoreAdjuster: WeightedResultScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedResultScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedResultScoreAdjuster: WeightedResultScoreStep {
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

        func adjust(_ item: WeightedResultScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameWeightedResultScoreAdjuster: WeightedResultScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedResultScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWeightedResultScoreAdjuster: WeightedResultScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedResultScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted result score steps in order and keeps a trace of each.
    final class WeightedResultScoreEngine {
        var steps: [any WeightedResultScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedResultScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedResultScore) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [WeightedResultScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedResultScoreEngine(_ flags: Kit.Flags.Registry) -> WeightedResultScoreEngine {
        return WeightedResultScoreEngine(
            steps: [
                PercentWeightedResultScoreAdjuster(percent: -4.4),
                FlaggedWeightedResultScoreAdjuster(flags: flags, flag: "weighted-result-score-default", percent: 6.2),
                NameWeightedResultScoreAdjuster(factors: ["east": 1.33, "north": 0.97]),
                RoundingWeightedResultScoreAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 86423.2
        )
    }
}
