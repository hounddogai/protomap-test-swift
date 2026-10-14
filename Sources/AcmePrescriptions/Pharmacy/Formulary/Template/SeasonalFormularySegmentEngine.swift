import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal formulary segment calculation.
    protocol SeasonalFormularySegmentModifier {
        func describe() -> String
        func adjust(_ item: SeasonalFormularySegment, value: Double) -> Double
    }

    final class SeasonalFormularySegmentMinimumOffsetAdjuster: SeasonalFormularySegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: SeasonalFormularySegment, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class TieredSeasonalFormularySegmentAdjuster: SeasonalFormularySegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalFormularySegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapSeasonalFormularySegmentAdjuster: SeasonalFormularySegmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalFormularySegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSeasonalFormularySegmentAdjuster: SeasonalFormularySegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalFormularySegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSeasonalFormularySegmentAdjuster: SeasonalFormularySegmentModifier {
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

        func adjust(_ item: SeasonalFormularySegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSeasonalFormularySegmentAdjuster: SeasonalFormularySegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalFormularySegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal formulary segment steps in order and keeps a trace of each.
    final class SeasonalFormularySegmentEngine {
        var steps: [any SeasonalFormularySegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalFormularySegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalFormularySegment) -> Double {
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

        func evaluateAll(_ items: [SeasonalFormularySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalFormularySegmentEngine(_ flags: Kit.Flags.Registry) -> SeasonalFormularySegmentEngine {
        return SeasonalFormularySegmentEngine(
            steps: [
                SeasonalFormularySegmentMinimumOffsetAdjuster(weight: 1.4),
                TieredSeasonalFormularySegmentAdjuster(bounds: [1234.0, 6981.0], rates: [1.04, 1.08]),
                CapSeasonalFormularySegmentAdjuster(cap: 10400.0),
                RoundingSeasonalFormularySegmentAdjuster(step: 0.5),
                FlaggedSeasonalFormularySegmentAdjuster(
                    flags: flags,
                    flag: "seasonal-formulary-segment-seasonal",
                    percent: 3.8
                ),
                PercentSeasonalFormularySegmentAdjuster(percent: 9.9),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 76732.4
        )
    }
}
