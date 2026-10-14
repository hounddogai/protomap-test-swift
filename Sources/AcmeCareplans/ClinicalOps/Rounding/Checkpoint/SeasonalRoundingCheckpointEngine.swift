import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal rounding checkpoint calculation.
    protocol SeasonalRoundingCheckpointStep {
        func describe() -> String
        func adjust(_ item: SeasonalRoundingCheckpoint, value: Double) -> Double
    }

    final class RoundingSeasonalRoundingCheckpointAdjuster: SeasonalRoundingCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalRoundingCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelSeasonalRoundingCheckpointAdjuster: SeasonalRoundingCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: SeasonalRoundingCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalRoundingCheckpointAdjuster: SeasonalRoundingCheckpointStep {
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

        func adjust(_ item: SeasonalRoundingCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal rounding checkpoint steps in order and keeps a trace of each.
    final class SeasonalRoundingCheckpointEngine {
        var steps: [any SeasonalRoundingCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRoundingCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalRoundingCheckpoint) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalRoundingCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalRoundingCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalRoundingCheckpointEngine(_ flags: Kit.Flags.Registry) -> SeasonalRoundingCheckpointEngine {
        return SeasonalRoundingCheckpointEngine(
            steps: [
                RoundingSeasonalRoundingCheckpointAdjuster(step: 0.05),
                ChannelSeasonalRoundingCheckpointAdjuster(factors: ["west": 0.92, "south": 0.81]),
                FlaggedSeasonalRoundingCheckpointAdjuster(
                    flags: flags,
                    flag: "seasonal-rounding-checkpoint-scheduled",
                    percent: 1.7
                ),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 15124.7
        )
    }
}
