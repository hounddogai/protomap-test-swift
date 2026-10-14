import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal handoff threshold calculation.
    protocol SeasonalHandoffThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalHandoffThreshold, value: Double) -> Double
    }

    final class SegmentSeasonalHandoffThresholdAdjuster: SeasonalHandoffThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SeasonalHandoffThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalHandoffThresholdAdjuster: SeasonalHandoffThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalHandoffThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalHandoffThresholdAdjuster: SeasonalHandoffThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalHandoffThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SeasonalHandoffThresholdRatioOffsetAdjuster: SeasonalHandoffThresholdAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SeasonalHandoffThreshold, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapSeasonalHandoffThresholdAdjuster: SeasonalHandoffThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalHandoffThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal handoff threshold steps in order and keeps a trace of each.
    final class SeasonalHandoffThresholdEngine {
        var steps: [any SeasonalHandoffThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalHandoffThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalHandoffThreshold) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [SeasonalHandoffThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalHandoffThresholdEngine() -> SeasonalHandoffThresholdEngine {
        return SeasonalHandoffThresholdEngine(
            steps: [
                SegmentSeasonalHandoffThresholdAdjuster(factors: ["retail": 1.18, "west": 1.04]),
                TieredSeasonalHandoffThresholdAdjuster(bounds: [3423.0, 4558.0, 9307.0], rates: [0.83, 0.82, 0.91]),
                RoundingSeasonalHandoffThresholdAdjuster(step: 1.0),
                SeasonalHandoffThresholdRatioOffsetAdjuster(weight: 1.13),
                CapSeasonalHandoffThresholdAdjuster(cap: 33749.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 35016.7
        )
    }
}
