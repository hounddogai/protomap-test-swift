import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the weighted remittance request calculation.
    protocol WeightedRemittanceRequestFactor {
        func describe() -> String
        func adjust(_ item: WeightedRemittanceRequest, value: Double) -> Double
    }

    final class WeightedRemittanceRequestScoreOffsetAdjuster: WeightedRemittanceRequestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: WeightedRemittanceRequest, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapWeightedRemittanceRequestAdjuster: WeightedRemittanceRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedRemittanceRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumWeightedRemittanceRequestAdjuster: WeightedRemittanceRequestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedRemittanceRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWeightedRemittanceRequestAdjuster: WeightedRemittanceRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedRemittanceRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedRemittanceRequestAdjuster: WeightedRemittanceRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedRemittanceRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedRemittanceRequestAdjuster: WeightedRemittanceRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedRemittanceRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted remittance request steps in order and keeps a trace of each.
    final class WeightedRemittanceRequestEngine {
        var steps: [any WeightedRemittanceRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedRemittanceRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedRemittanceRequest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedRemittanceRequestFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedRemittanceRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedRemittanceRequestEngine() -> WeightedRemittanceRequestEngine {
        return WeightedRemittanceRequestEngine(
            steps: [
                WeightedRemittanceRequestScoreOffsetAdjuster(weight: 1.69),
                CapWeightedRemittanceRequestAdjuster(cap: 14431.0),
                MinimumWeightedRemittanceRequestAdjuster(minimum: 14.9),
                TieredWeightedRemittanceRequestAdjuster(
                    bounds: [1880.0, 3711.0, 9627.0, 9953.0],
                    rates: [1.18, 0.99, 0.89, 0.95]
                ),
                RoundingWeightedRemittanceRequestAdjuster(step: 0.05),
                PercentWeightedRemittanceRequestAdjuster(percent: -1.8),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 84506.3
        )
    }
}
