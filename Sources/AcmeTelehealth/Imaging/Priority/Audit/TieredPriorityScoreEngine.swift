import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered priority score calculation.
    protocol TieredPriorityScoreModifier {
        func describe() -> String
        func adjust(_ item: TieredPriorityScore, value: Double) -> Double
    }

    final class MinimumTieredPriorityScoreAdjuster: TieredPriorityScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredPriorityScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPriorityScoreDurationMinutesOffsetAdjuster: TieredPriorityScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: TieredPriorityScore, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedTieredPriorityScoreAdjuster: TieredPriorityScoreModifier {
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

        func adjust(_ item: TieredPriorityScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredPriorityScoreAdjuster: TieredPriorityScoreModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredPriorityScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredPriorityScoreAdjuster: TieredPriorityScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredPriorityScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredPriorityScoreAdjuster: TieredPriorityScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredPriorityScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered priority score steps in order and keeps a trace of each.
    final class TieredPriorityScoreEngine {
        var steps: [any TieredPriorityScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredPriorityScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredPriorityScore) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredPriorityScoreModifier = steps[index]
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

        func evaluateAll(_ items: [TieredPriorityScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredPriorityScoreEngine(_ flags: Kit.Flags.Registry) -> TieredPriorityScoreEngine {
        return TieredPriorityScoreEngine(
            steps: [
                MinimumTieredPriorityScoreAdjuster(minimum: 39.3),
                TieredPriorityScoreDurationMinutesOffsetAdjuster(weight: 1.98),
                FlaggedTieredPriorityScoreAdjuster(flags: flags, flag: "tiered-priority-score-legacy", percent: -9.2),
                TieredTieredPriorityScoreAdjuster(bounds: [3894.0, 6173.0, 9920.0], rates: [0.85, 0.81, 0.89]),
                PercentTieredPriorityScoreAdjuster(percent: -23.4),
                RoundingTieredPriorityScoreAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 35282.1
        )
    }
}
