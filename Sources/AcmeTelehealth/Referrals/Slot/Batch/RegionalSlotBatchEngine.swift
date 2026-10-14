import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional slot batch calculation.
    protocol RegionalSlotBatchAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalSlotBatch, value: Double) -> Double
    }

    final class MinimumRegionalSlotBatchAdjuster: RegionalSlotBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalSlotBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRegionalSlotBatchAdjuster: RegionalSlotBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalSlotBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRegionalSlotBatchAdjuster: RegionalSlotBatchAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalSlotBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional slot batch steps in order and keeps a trace of each.
    final class RegionalSlotBatchEngine {
        var steps: [any RegionalSlotBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSlotBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalSlotBatch) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalSlotBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalSlotBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalSlotBatchEngine() -> RegionalSlotBatchEngine {
        return RegionalSlotBatchEngine(
            steps: [
                MinimumRegionalSlotBatchAdjuster(minimum: 25.9),
                RoundingRegionalSlotBatchAdjuster(step: 1.0),
                TieredRegionalSlotBatchAdjuster(bounds: [947.0, 5412.0, 7447.0], rates: [1.14, 0.8, 0.82]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 13295.6
        )
    }
}
