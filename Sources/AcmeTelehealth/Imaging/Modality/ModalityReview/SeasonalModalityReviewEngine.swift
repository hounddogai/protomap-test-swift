import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal modality review calculation.
    protocol SeasonalModalityReviewStep {
        func describe() -> String
        func adjust(_ item: SeasonalModalityReview, value: Double) -> Double
    }

    final class MinimumSeasonalModalityReviewAdjuster: SeasonalModalityReviewStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalModalityReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameSeasonalModalityReviewAdjuster: SeasonalModalityReviewStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalModalityReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalModalityReviewCreatedAtOffsetAdjuster: SeasonalModalityReviewStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: SeasonalModalityReview, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class FlaggedSeasonalModalityReviewAdjuster: SeasonalModalityReviewStep {
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

        func adjust(_ item: SeasonalModalityReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalModalityReviewAdjuster: SeasonalModalityReviewStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalModalityReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal modality review steps in order and keeps a trace of each.
    final class SeasonalModalityReviewEngine {
        var steps: [any SeasonalModalityReviewStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalModalityReviewStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalModalityReview) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [SeasonalModalityReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalModalityReviewEngine(_ flags: Kit.Flags.Registry) -> SeasonalModalityReviewEngine {
        return SeasonalModalityReviewEngine(
            steps: [
                MinimumSeasonalModalityReviewAdjuster(minimum: 34.2),
                NameSeasonalModalityReviewAdjuster(factors: ["south": 1.29, "east": 1.25, "west": 0.92]),
                SeasonalModalityReviewCreatedAtOffsetAdjuster(weight: 0.04),
                FlaggedSeasonalModalityReviewAdjuster(
                    flags: flags,
                    flag: "seasonal-modality-review-primary",
                    percent: -5.8
                ),
                CapSeasonalModalityReviewAdjuster(cap: 26488.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 55355.1
        )
    }
}
