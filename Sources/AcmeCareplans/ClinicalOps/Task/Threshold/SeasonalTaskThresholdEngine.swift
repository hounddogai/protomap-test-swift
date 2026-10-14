import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal task threshold calculation.
    protocol SeasonalTaskThresholdStep {
        func describe() -> String
        func adjust(_ item: SeasonalTaskThreshold, value: Double) -> Double
    }

    final class MinimumSeasonalTaskThresholdAdjuster: SeasonalTaskThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalTaskThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalTaskThresholdAdjuster: SeasonalTaskThresholdStep {
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

        func adjust(_ item: SeasonalTaskThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalTaskThresholdAdjuster: SeasonalTaskThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalTaskThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameSeasonalTaskThresholdAdjuster: SeasonalTaskThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalTaskThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal task threshold steps in order and keeps a trace of each.
    final class SeasonalTaskThresholdEngine {
        var steps: [any SeasonalTaskThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalTaskThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalTaskThreshold) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalTaskThresholdStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalTaskThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalTaskThresholdEngine(_ flags: Kit.Flags.Registry) -> SeasonalTaskThresholdEngine {
        return SeasonalTaskThresholdEngine(
            steps: [
                MinimumSeasonalTaskThresholdAdjuster(minimum: 32.5),
                FlaggedSeasonalTaskThresholdAdjuster(
                    flags: flags,
                    flag: "seasonal-task-threshold-seasonal",
                    percent: -9.0
                ),
                RoundingSeasonalTaskThresholdAdjuster(step: 0.25),
                NameSeasonalTaskThresholdAdjuster(factors: ["online": 1.14, "east": 0.77, "south": 1.09]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 62411.9
        )
    }
}
