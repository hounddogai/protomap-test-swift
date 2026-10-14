import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal courier segment calculation.
    protocol SeasonalCourierSegmentModifier {
        func describe() -> String
        func adjust(_ item: SeasonalCourierSegment, value: Double) -> Double
    }

    final class FacilitySeasonalCourierSegmentAdjuster: SeasonalCourierSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SeasonalCourierSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalCourierSegmentAdjuster: SeasonalCourierSegmentModifier {
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

        func adjust(_ item: SeasonalCourierSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalCourierSegmentAdjuster: SeasonalCourierSegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalCourierSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal courier segment steps in order and keeps a trace of each.
    final class SeasonalCourierSegmentEngine {
        var steps: [any SeasonalCourierSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCourierSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalCourierSegment) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalCourierSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalCourierSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalCourierSegmentEngine(_ flags: Kit.Flags.Registry) -> SeasonalCourierSegmentEngine {
        return SeasonalCourierSegmentEngine(
            steps: [
                FacilitySeasonalCourierSegmentAdjuster(factors: ["north": 0.94, "central": 1.04, "south": 0.89]),
                FlaggedSeasonalCourierSegmentAdjuster(
                    flags: flags,
                    flag: "seasonal-courier-segment-tiered",
                    percent: 9.6
                ),
                TieredSeasonalCourierSegmentAdjuster(bounds: [2066.0, 9041.0], rates: [0.95, 0.92]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 76417.0
        )
    }
}
