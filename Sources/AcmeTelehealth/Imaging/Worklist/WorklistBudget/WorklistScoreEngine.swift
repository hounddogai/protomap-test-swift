import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist score calculation.
    protocol WorklistScoreFactor {
        func describe() -> String
        func adjust(_ item: WorklistScore, value: Double) -> Double
    }

    final class MinimumWorklistScoreAdjuster: WorklistScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWorklistScoreAdjuster: WorklistScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWorklistScoreAdjuster: WorklistScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWorklistScoreAdjuster: WorklistScoreFactor {
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

        func adjust(_ item: WorklistScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWorklistScoreAdjuster: WorklistScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelWorklistScoreAdjuster: WorklistScoreFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: WorklistScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the worklist score steps in order and keeps a trace of each.
    final class WorklistScoreEngine {
        var steps: [any WorklistScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WorklistScore) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistScoreFactor = steps[index]
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

        func evaluateAll(_ items: [WorklistScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWorklistScoreEngine(_ flags: Kit.Flags.Registry) -> WorklistScoreEngine {
        return WorklistScoreEngine(
            steps: [
                MinimumWorklistScoreAdjuster(minimum: 42.7),
                TieredWorklistScoreAdjuster(bounds: [4160.0, 7650.0, 9379.0, 9737.0], rates: [1.18, 1.03, 0.87, 0.96]),
                RoundingWorklistScoreAdjuster(step: 0.05),
                FlaggedWorklistScoreAdjuster(flags: flags, flag: "worklist-score-lenient", percent: -5.3),
                CapWorklistScoreAdjuster(cap: 37308.0),
                ChannelWorklistScoreAdjuster(factors: ["east": 1.03]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 16026.7
        )
    }
}
