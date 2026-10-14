import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal rounding estimate calculation.
    protocol SeasonalRoundingEstimateStep {
        func describe() -> String
        func adjust(_ item: SeasonalRoundingEstimate, value: Double) -> Double
    }

    final class FlaggedSeasonalRoundingEstimateAdjuster: SeasonalRoundingEstimateStep {
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

        func adjust(_ item: SeasonalRoundingEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceSeasonalRoundingEstimateAdjuster: SeasonalRoundingEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SeasonalRoundingEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalRoundingEstimateExpiresAtOffsetAdjuster: SeasonalRoundingEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: SeasonalRoundingEstimate, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumSeasonalRoundingEstimateAdjuster: SeasonalRoundingEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalRoundingEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSeasonalRoundingEstimateAdjuster: SeasonalRoundingEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalRoundingEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal rounding estimate steps in order and keeps a trace of each.
    final class SeasonalRoundingEstimateEngine {
        var steps: [any SeasonalRoundingEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalRoundingEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalRoundingEstimate) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [SeasonalRoundingEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalRoundingEstimateEngine(_ flags: Kit.Flags.Registry) -> SeasonalRoundingEstimateEngine {
        return SeasonalRoundingEstimateEngine(
            steps: [
                FlaggedSeasonalRoundingEstimateAdjuster(
                    flags: flags,
                    flag: "seasonal-rounding-estimate-lenient",
                    percent: 1.8
                ),
                SourceSeasonalRoundingEstimateAdjuster(factors: ["east": 1.39]),
                SeasonalRoundingEstimateExpiresAtOffsetAdjuster(weight: 1.75),
                MinimumSeasonalRoundingEstimateAdjuster(minimum: 48.5),
                CapSeasonalRoundingEstimateAdjuster(cap: 16957.0),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 49005.5
        )
    }
}
