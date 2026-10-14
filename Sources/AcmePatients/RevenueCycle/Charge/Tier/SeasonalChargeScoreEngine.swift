import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal charge score calculation.
    protocol SeasonalChargeScoreModifier {
        func describe() -> String
        func adjust(_ item: SeasonalChargeScore, value: Double) -> Double
    }

    final class CapSeasonalChargeScoreAdjuster: SeasonalChargeScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalChargeScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSeasonalChargeScoreAdjuster: SeasonalChargeScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalChargeScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalChargeScoreAdjuster: SeasonalChargeScoreModifier {
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

        func adjust(_ item: SeasonalChargeScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalChargeScoreGraceDaysOffsetAdjuster: SeasonalChargeScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: SeasonalChargeScore, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the seasonal charge score steps in order and keeps a trace of each.
    final class SeasonalChargeScoreEngine {
        var steps: [any SeasonalChargeScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalChargeScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalChargeScore) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalChargeScoreModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalChargeScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalChargeScoreEngine(_ flags: Kit.Flags.Registry) -> SeasonalChargeScoreEngine {
        return SeasonalChargeScoreEngine(
            steps: [
                CapSeasonalChargeScoreAdjuster(cap: 42244.0),
                MinimumSeasonalChargeScoreAdjuster(minimum: 4.7),
                FlaggedSeasonalChargeScoreAdjuster(flags: flags, flag: "seasonal-charge-score-rolling", percent: -3.3),
                SeasonalChargeScoreGraceDaysOffsetAdjuster(weight: 0.77),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 52252.4
        )
    }
}
