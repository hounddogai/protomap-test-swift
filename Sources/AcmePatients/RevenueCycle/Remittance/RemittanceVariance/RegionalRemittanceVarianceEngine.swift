import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the regional remittance variance calculation.
    protocol RegionalRemittanceVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalRemittanceVariance, value: Double) -> Double
    }

    final class PercentRegionalRemittanceVarianceAdjuster: RegionalRemittanceVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalRemittanceVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalRemittanceVarianceUpdatedAtOffsetAdjuster: RegionalRemittanceVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RegionalRemittanceVariance, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class MinimumRegionalRemittanceVarianceAdjuster: RegionalRemittanceVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalRemittanceVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRegionalRemittanceVarianceAdjuster: RegionalRemittanceVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalRemittanceVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalRemittanceVarianceAdjuster: RegionalRemittanceVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalRemittanceVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalRemittanceVarianceAdjuster: RegionalRemittanceVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalRemittanceVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional remittance variance steps in order and keeps a trace of each.
    final class RegionalRemittanceVarianceEngine {
        var steps: [any RegionalRemittanceVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalRemittanceVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalRemittanceVariance) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalRemittanceVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalRemittanceVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalRemittanceVarianceEngine() -> RegionalRemittanceVarianceEngine {
        return RegionalRemittanceVarianceEngine(
            steps: [
                PercentRegionalRemittanceVarianceAdjuster(percent: 23.0),
                RegionalRemittanceVarianceUpdatedAtOffsetAdjuster(weight: 0.53),
                MinimumRegionalRemittanceVarianceAdjuster(minimum: 38.0),
                CapRegionalRemittanceVarianceAdjuster(cap: 36579.0),
                TieredRegionalRemittanceVarianceAdjuster(
                    bounds: [1166.0, 1457.0, 2633.0, 7636.0],
                    rates: [0.94, 1.1, 0.98, 1.04]
                ),
                RoundingRegionalRemittanceVarianceAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 16782.3
        )
    }
}
