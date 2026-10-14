import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal study batch calculation.
    protocol SeasonalStudyBatchStep {
        func describe() -> String
        func adjust(_ item: SeasonalStudyBatch, value: Double) -> Double
    }

    final class FlaggedSeasonalStudyBatchAdjuster: SeasonalStudyBatchStep {
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

        func adjust(_ item: SeasonalStudyBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalStudyBatchAdjuster: SeasonalStudyBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalStudyBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumSeasonalStudyBatchAdjuster: SeasonalStudyBatchStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalStudyBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilitySeasonalStudyBatchAdjuster: SeasonalStudyBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SeasonalStudyBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal study batch steps in order and keeps a trace of each.
    final class SeasonalStudyBatchEngine {
        var steps: [any SeasonalStudyBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalStudyBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalStudyBatch) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalStudyBatchStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalStudyBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalStudyBatchEngine(_ flags: Kit.Flags.Registry) -> SeasonalStudyBatchEngine {
        return SeasonalStudyBatchEngine(
            steps: [
                FlaggedSeasonalStudyBatchAdjuster(flags: flags, flag: "seasonal-study-batch-scheduled", percent: -0.7),
                CapSeasonalStudyBatchAdjuster(cap: 28752.0),
                MinimumSeasonalStudyBatchAdjuster(minimum: 21.6),
                FacilitySeasonalStudyBatchAdjuster(factors: ["central": 0.87, "north": 1.28, "retail": 1.17]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 63650.6
        )
    }
}
