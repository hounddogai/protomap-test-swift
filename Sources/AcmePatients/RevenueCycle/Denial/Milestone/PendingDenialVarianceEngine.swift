import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending denial variance calculation.
    protocol PendingDenialVarianceFactor {
        func describe() -> String
        func adjust(_ item: PendingDenialVariance, value: Double) -> Double
    }

    final class RoundingPendingDenialVarianceAdjuster: PendingDenialVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingDenialVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingDenialVarianceAdjuster: PendingDenialVarianceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingDenialVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitlePendingDenialVarianceAdjuster: PendingDenialVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PendingDenialVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PendingDenialVarianceWeightOffsetAdjuster: PendingDenialVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: PendingDenialVariance, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    /// Runs the pending denial variance steps in order and keeps a trace of each.
    final class PendingDenialVarianceEngine {
        var steps: [any PendingDenialVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingDenialVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingDenialVariance) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingDenialVarianceFactor = steps[index]
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

        func evaluateAll(_ items: [PendingDenialVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingDenialVarianceEngine() -> PendingDenialVarianceEngine {
        return PendingDenialVarianceEngine(
            steps: [
                RoundingPendingDenialVarianceAdjuster(step: 0.05),
                TieredPendingDenialVarianceAdjuster(bounds: [379.0, 9559.0], rates: [0.99, 0.8]),
                TitlePendingDenialVarianceAdjuster(factors: ["retail": 1.28, "east": 1.38, "central": 1.03]),
                PendingDenialVarianceWeightOffsetAdjuster(weight: 1.95),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 53975.5
        )
    }
}
