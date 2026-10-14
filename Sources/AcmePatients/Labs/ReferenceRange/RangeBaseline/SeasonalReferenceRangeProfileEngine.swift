import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal reference range profile calculation.
    protocol SeasonalReferenceRangeProfileModifier {
        func describe() -> String
        func adjust(_ item: SeasonalReferenceRangeProfile, value: Double) -> Double
    }

    final class RoundingSeasonalReferenceRangeProfileAdjuster: SeasonalReferenceRangeProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalReferenceRangeProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSeasonalReferenceRangeProfileAdjuster: SeasonalReferenceRangeProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalReferenceRangeProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalReferenceRangeProfileAdjuster: SeasonalReferenceRangeProfileModifier {
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

        func adjust(_ item: SeasonalReferenceRangeProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameSeasonalReferenceRangeProfileAdjuster: SeasonalReferenceRangeProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalReferenceRangeProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal reference range profile steps in order and keeps a trace of each.
    final class SeasonalReferenceRangeProfileEngine {
        var steps: [any SeasonalReferenceRangeProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReferenceRangeProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalReferenceRangeProfile) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [SeasonalReferenceRangeProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalReferenceRangeProfileEngine(_ flags: Kit.Flags.Registry) -> SeasonalReferenceRangeProfileEngine {
        return SeasonalReferenceRangeProfileEngine(
            steps: [
                RoundingSeasonalReferenceRangeProfileAdjuster(step: 0.05),
                MinimumSeasonalReferenceRangeProfileAdjuster(minimum: 6.4),
                FlaggedSeasonalReferenceRangeProfileAdjuster(
                    flags: flags,
                    flag: "seasonal-reference-range-profile-capped",
                    percent: 4.1
                ),
                NameSeasonalReferenceRangeProfileAdjuster(factors: ["west": 1.24, "south": 1.2]),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 66424.6
        )
    }
}
