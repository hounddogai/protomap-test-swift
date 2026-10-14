import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict care protocol threshold calculation.
    protocol StrictCareProtocolThresholdStep {
        func describe() -> String
        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double
    }

    final class SegmentStrictCareProtocolThresholdAdjuster: StrictCareProtocolThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumStrictCareProtocolThresholdAdjuster: StrictCareProtocolThresholdStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStrictCareProtocolThresholdAdjuster: StrictCareProtocolThresholdStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class StrictCareProtocolThresholdSequenceOffsetAdjuster: StrictCareProtocolThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the strict care protocol threshold steps in order and keeps a trace of each.
    final class StrictCareProtocolThresholdEngine {
        var steps: [any StrictCareProtocolThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCareProtocolThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictCareProtocolThreshold) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictCareProtocolThresholdStep = steps[index]
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

        func evaluateAll(_ items: [StrictCareProtocolThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictCareProtocolThresholdEngine() -> StrictCareProtocolThresholdEngine {
        return StrictCareProtocolThresholdEngine(
            steps: [
                SegmentStrictCareProtocolThresholdAdjuster(factors: ["north": 1.2, "retail": 0.87, "west": 1.33]),
                MinimumStrictCareProtocolThresholdAdjuster(minimum: 10.8),
                TieredStrictCareProtocolThresholdAdjuster(
                    bounds: [23.0, 255.0, 4860.0, 7077.0],
                    rates: [1.07, 0.89, 1.13, 1.04]
                ),
                StrictCareProtocolThresholdSequenceOffsetAdjuster(weight: 1.35),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 20830.2
        )
    }
}
