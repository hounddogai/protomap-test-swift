import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal language checkpoint calculation.
    protocol SeasonalLanguageCheckpointModifier {
        func describe() -> String
        func adjust(_ item: SeasonalLanguageCheckpoint, value: Double) -> Double
    }

    final class SeasonalLanguageCheckpointMinimumOffsetAdjuster: SeasonalLanguageCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: SeasonalLanguageCheckpoint, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredSeasonalLanguageCheckpointAdjuster: SeasonalLanguageCheckpointModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalLanguageCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSeasonalLanguageCheckpointAdjuster: SeasonalLanguageCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalLanguageCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalLanguageCheckpointAdjuster: SeasonalLanguageCheckpointModifier {
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

        func adjust(_ item: SeasonalLanguageCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalLanguageCheckpointAdjuster: SeasonalLanguageCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalLanguageCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal language checkpoint steps in order and keeps a trace of each.
    final class SeasonalLanguageCheckpointEngine {
        var steps: [any SeasonalLanguageCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalLanguageCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalLanguageCheckpoint) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalLanguageCheckpointModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalLanguageCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalLanguageCheckpointEngine(_ flags: Kit.Flags.Registry) -> SeasonalLanguageCheckpointEngine {
        return SeasonalLanguageCheckpointEngine(
            steps: [
                SeasonalLanguageCheckpointMinimumOffsetAdjuster(weight: 0.51),
                TieredSeasonalLanguageCheckpointAdjuster(bounds: [6023.0, 6378.0], rates: [0.81, 1.0]),
                PercentSeasonalLanguageCheckpointAdjuster(percent: -18.8),
                FlaggedSeasonalLanguageCheckpointAdjuster(
                    flags: flags,
                    flag: "seasonal-language-checkpoint-adaptive",
                    percent: 4.3
                ),
                MinimumSeasonalLanguageCheckpointAdjuster(minimum: 27.3),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 40546.3
        )
    }
}
