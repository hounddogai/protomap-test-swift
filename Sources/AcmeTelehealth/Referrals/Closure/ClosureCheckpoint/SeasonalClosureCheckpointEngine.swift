import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal closure checkpoint calculation.
    protocol SeasonalClosureCheckpointFactor {
        func describe() -> String
        func adjust(_ item: SeasonalClosureCheckpoint, value: Double) -> Double
    }

    final class CapSeasonalClosureCheckpointAdjuster: SeasonalClosureCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalClosureCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentSeasonalClosureCheckpointAdjuster: SeasonalClosureCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalClosureCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalClosureCheckpointAdjuster: SeasonalClosureCheckpointFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalClosureCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalClosureCheckpointWindowDaysOffsetAdjuster: SeasonalClosureCheckpointFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: SeasonalClosureCheckpoint, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class MinimumSeasonalClosureCheckpointAdjuster: SeasonalClosureCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalClosureCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalClosureCheckpointAdjuster: SeasonalClosureCheckpointFactor {
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

        func adjust(_ item: SeasonalClosureCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal closure checkpoint steps in order and keeps a trace of each.
    final class SeasonalClosureCheckpointEngine {
        var steps: [any SeasonalClosureCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalClosureCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalClosureCheckpoint) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [SeasonalClosureCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalClosureCheckpointEngine(_ flags: Kit.Flags.Registry) -> SeasonalClosureCheckpointEngine {
        return SeasonalClosureCheckpointEngine(
            steps: [
                CapSeasonalClosureCheckpointAdjuster(cap: 18179.0),
                PercentSeasonalClosureCheckpointAdjuster(percent: 10.4),
                TieredSeasonalClosureCheckpointAdjuster(
                    bounds: [642.0, 1768.0, 9288.0, 9666.0],
                    rates: [0.82, 0.82, 1.09, 0.84]
                ),
                SeasonalClosureCheckpointWindowDaysOffsetAdjuster(weight: 0.84),
                MinimumSeasonalClosureCheckpointAdjuster(minimum: 48.7),
                FlaggedSeasonalClosureCheckpointAdjuster(
                    flags: flags,
                    flag: "seasonal-closure-checkpoint-strict",
                    percent: -6.1
                ),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 92711.7
        )
    }
}
