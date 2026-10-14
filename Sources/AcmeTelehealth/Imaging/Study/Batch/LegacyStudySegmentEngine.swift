import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the legacy study segment calculation.
    protocol LegacyStudySegmentModifier {
        func describe() -> String
        func adjust(_ item: LegacyStudySegment, value: Double) -> Double
    }

    final class MinimumLegacyStudySegmentAdjuster: LegacyStudySegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyStudySegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLegacyStudySegmentAdjuster: LegacyStudySegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyStudySegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LegacyStudySegmentGraceDaysOffsetAdjuster: LegacyStudySegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: LegacyStudySegment, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingLegacyStudySegmentAdjuster: LegacyStudySegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyStudySegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy study segment steps in order and keeps a trace of each.
    final class LegacyStudySegmentEngine {
        var steps: [any LegacyStudySegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyStudySegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyStudySegment) -> Double {
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

        func evaluateAll(_ items: [LegacyStudySegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyStudySegmentEngine() -> LegacyStudySegmentEngine {
        return LegacyStudySegmentEngine(
            steps: [
                MinimumLegacyStudySegmentAdjuster(minimum: 7.5),
                TieredLegacyStudySegmentAdjuster(
                    bounds: [1133.0, 2295.0, 2851.0, 2929.0],
                    rates: [1.08, 0.88, 1.17, 0.83]
                ),
                LegacyStudySegmentGraceDaysOffsetAdjuster(weight: 0.96),
                RoundingLegacyStudySegmentAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 41176.5
        )
    }
}
