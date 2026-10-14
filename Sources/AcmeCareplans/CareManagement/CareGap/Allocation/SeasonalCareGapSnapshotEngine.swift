import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal care gap snapshot calculation.
    protocol SeasonalCareGapSnapshotModifier {
        func describe() -> String
        func adjust(_ item: SeasonalCareGapSnapshot, value: Double) -> Double
    }

    final class TieredSeasonalCareGapSnapshotAdjuster: SeasonalCareGapSnapshotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalCareGapSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSeasonalCareGapSnapshotAdjuster: SeasonalCareGapSnapshotModifier {
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

        func adjust(_ item: SeasonalCareGapSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelSeasonalCareGapSnapshotAdjuster: SeasonalCareGapSnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: SeasonalCareGapSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalCareGapSnapshotFloorValueOffsetAdjuster: SeasonalCareGapSnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: SeasonalCareGapSnapshot, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class RoundingSeasonalCareGapSnapshotAdjuster: SeasonalCareGapSnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalCareGapSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentSeasonalCareGapSnapshotAdjuster: SeasonalCareGapSnapshotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalCareGapSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal care gap snapshot steps in order and keeps a trace of each.
    final class SeasonalCareGapSnapshotEngine {
        var steps: [any SeasonalCareGapSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCareGapSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalCareGapSnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [SeasonalCareGapSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalCareGapSnapshotEngine(_ flags: Kit.Flags.Registry) -> SeasonalCareGapSnapshotEngine {
        return SeasonalCareGapSnapshotEngine(
            steps: [
                TieredSeasonalCareGapSnapshotAdjuster(bounds: [6460.0, 8550.0, 8708.0], rates: [1.12, 1.14, 1.02]),
                FlaggedSeasonalCareGapSnapshotAdjuster(
                    flags: flags,
                    flag: "seasonal-care-gap-snapshot-strict",
                    percent: -9.3
                ),
                ChannelSeasonalCareGapSnapshotAdjuster(factors: ["north": 0.79]),
                SeasonalCareGapSnapshotFloorValueOffsetAdjuster(weight: 1.31),
                RoundingSeasonalCareGapSnapshotAdjuster(step: 5.0),
                PercentSeasonalCareGapSnapshotAdjuster(percent: 14.5),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 91131.2
        )
    }
}
