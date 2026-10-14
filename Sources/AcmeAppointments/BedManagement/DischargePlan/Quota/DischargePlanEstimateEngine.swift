import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan estimate calculation.
    protocol DischargePlanEstimateFactor {
        func describe() -> String
        func adjust(_ item: DischargePlanEstimate, value: Double) -> Double
    }

    final class RoundingDischargePlanEstimateAdjuster: DischargePlanEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumDischargePlanEstimateAdjuster: DischargePlanEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDischargePlanEstimateAdjuster: DischargePlanEstimateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the discharge plan estimate steps in order and keeps a trace of each.
    final class DischargePlanEstimateEngine {
        var steps: [any DischargePlanEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DischargePlanEstimate) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [DischargePlanEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDischargePlanEstimateEngine() -> DischargePlanEstimateEngine {
        return DischargePlanEstimateEngine(
            steps: [
                RoundingDischargePlanEstimateAdjuster(step: 1.0),
                MinimumDischargePlanEstimateAdjuster(minimum: 22.2),
                TieredDischargePlanEstimateAdjuster(bounds: [109.0, 2028.0, 4350.0], rates: [0.82, 1.17, 0.82]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 16057.7
        )
    }
}
