import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal accession segment calculation.
    protocol SeasonalAccessionSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalAccessionSegment, value: Double) -> Double
    }

    final class MinimumSeasonalAccessionSegmentAdjuster: SeasonalAccessionSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalAccessionSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelSeasonalAccessionSegmentAdjuster: SeasonalAccessionSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalAccessionSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalAccessionSegmentAdjuster: SeasonalAccessionSegmentAdjuster {
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

        func adjust(_ item: SeasonalAccessionSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal accession segment steps in order and keeps a trace of each.
    final class SeasonalAccessionSegmentEngine {
        var steps: [any SeasonalAccessionSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalAccessionSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalAccessionSegment) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalAccessionSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalAccessionSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalAccessionSegmentEngine(_ flags: Kit.Flags.Registry) -> SeasonalAccessionSegmentEngine {
        return SeasonalAccessionSegmentEngine(
            steps: [
                MinimumSeasonalAccessionSegmentAdjuster(minimum: 48.4),
                LabelSeasonalAccessionSegmentAdjuster(factors: ["central": 0.95]),
                FlaggedSeasonalAccessionSegmentAdjuster(
                    flags: flags,
                    flag: "seasonal-accession-segment-fallback",
                    percent: 9.1
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 86891.4
        )
    }
}
