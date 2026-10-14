import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal care gap threshold calculation.
    protocol SeasonalCareGapThresholdStep {
        func describe() -> String
        func adjust(_ item: SeasonalCareGapThreshold, value: Double) -> Double
    }

    final class PercentSeasonalCareGapThresholdAdjuster: SeasonalCareGapThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalCareGapThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalCareGapThresholdCreatedAtOffsetAdjuster: SeasonalCareGapThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: SeasonalCareGapThreshold, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FlaggedSeasonalCareGapThresholdAdjuster: SeasonalCareGapThresholdStep {
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

        func adjust(_ item: SeasonalCareGapThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalCareGapThresholdAdjuster: SeasonalCareGapThresholdStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalCareGapThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameSeasonalCareGapThresholdAdjuster: SeasonalCareGapThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalCareGapThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalCareGapThresholdAdjuster: SeasonalCareGapThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCareGapThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal care gap threshold steps in order and keeps a trace of each.
    final class SeasonalCareGapThresholdEngine {
        var steps: [any SeasonalCareGapThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCareGapThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalCareGapThreshold) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalCareGapThresholdStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalCareGapThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalCareGapThresholdEngine(_ flags: Kit.Flags.Registry) -> SeasonalCareGapThresholdEngine {
        return SeasonalCareGapThresholdEngine(
            steps: [
                PercentSeasonalCareGapThresholdAdjuster(percent: -23.0),
                SeasonalCareGapThresholdCreatedAtOffsetAdjuster(weight: 0.07),
                FlaggedSeasonalCareGapThresholdAdjuster(
                    flags: flags,
                    flag: "seasonal-care-gap-threshold-adaptive",
                    percent: 4.7
                ),
                CapSeasonalCareGapThresholdAdjuster(cap: 15403.0),
                NameSeasonalCareGapThresholdAdjuster(factors: ["north": 0.87, "east": 0.79]),
                MinimumSeasonalCareGapThresholdAdjuster(minimum: 44.6),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 42075.5
        )
    }
}
