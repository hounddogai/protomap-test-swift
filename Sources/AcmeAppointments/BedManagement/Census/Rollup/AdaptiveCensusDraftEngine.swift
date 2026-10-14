import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive census draft calculation.
    protocol AdaptiveCensusDraftAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveCensusDraft, value: Double) -> Double
    }

    final class TieredAdaptiveCensusDraftAdjuster: AdaptiveCensusDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCensusDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAdaptiveCensusDraftAdjuster: AdaptiveCensusDraftAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveCensusDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAdaptiveCensusDraftAdjuster: AdaptiveCensusDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveCensusDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AdaptiveCensusDraftCostOffsetAdjuster: AdaptiveCensusDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: AdaptiveCensusDraft, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the adaptive census draft steps in order and keeps a trace of each.
    final class AdaptiveCensusDraftEngine {
        var steps: [any AdaptiveCensusDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCensusDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveCensusDraft) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveCensusDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveCensusDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCensusDraftEngine() -> AdaptiveCensusDraftEngine {
        return AdaptiveCensusDraftEngine(
            steps: [
                TieredAdaptiveCensusDraftAdjuster(bounds: [8540.0, 8624.0], rates: [0.84, 0.8]),
                MinimumAdaptiveCensusDraftAdjuster(minimum: 18.9),
                RoundingAdaptiveCensusDraftAdjuster(step: 5.0),
                AdaptiveCensusDraftCostOffsetAdjuster(weight: 0.69),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 81036.7
        )
    }
}
