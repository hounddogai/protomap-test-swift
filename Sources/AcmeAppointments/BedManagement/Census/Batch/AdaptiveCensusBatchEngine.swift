import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive census batch calculation.
    protocol AdaptiveCensusBatchFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveCensusBatch, value: Double) -> Double
    }

    final class TieredAdaptiveCensusBatchAdjuster: AdaptiveCensusBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCensusBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentAdaptiveCensusBatchAdjuster: AdaptiveCensusBatchFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveCensusBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAdaptiveCensusBatchAdjuster: AdaptiveCensusBatchFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveCensusBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the adaptive census batch steps in order and keeps a trace of each.
    final class AdaptiveCensusBatchEngine {
        var steps: [any AdaptiveCensusBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCensusBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveCensusBatch) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveCensusBatchFactor = steps[index]
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

        func evaluateAll(_ items: [AdaptiveCensusBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCensusBatchEngine() -> AdaptiveCensusBatchEngine {
        return AdaptiveCensusBatchEngine(
            steps: [
                TieredAdaptiveCensusBatchAdjuster(bounds: [2582.0, 4904.0, 7709.0], rates: [0.8, 0.9, 1.09]),
                PercentAdaptiveCensusBatchAdjuster(percent: 22.9),
                MinimumAdaptiveCensusBatchAdjuster(minimum: 42.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 11873.2
        )
    }
}
