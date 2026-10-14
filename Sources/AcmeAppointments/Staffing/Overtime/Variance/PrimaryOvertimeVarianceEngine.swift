import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary overtime variance calculation.
    protocol PrimaryOvertimeVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryOvertimeVariance, value: Double) -> Double
    }

    final class RoundingPrimaryOvertimeVarianceAdjuster: PrimaryOvertimeVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryOvertimeVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimaryOvertimeVarianceAdjuster: PrimaryOvertimeVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOvertimeVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryOvertimeVarianceAdjuster: PrimaryOvertimeVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOvertimeVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary overtime variance steps in order and keeps a trace of each.
    final class PrimaryOvertimeVarianceEngine {
        var steps: [any PrimaryOvertimeVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOvertimeVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryOvertimeVariance) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [PrimaryOvertimeVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryOvertimeVarianceEngine() -> PrimaryOvertimeVarianceEngine {
        return PrimaryOvertimeVarianceEngine(
            steps: [
                RoundingPrimaryOvertimeVarianceAdjuster(step: 0.5),
                PercentPrimaryOvertimeVarianceAdjuster(percent: -13.6),
                TieredPrimaryOvertimeVarianceAdjuster(bounds: [3534.0, 3952.0], rates: [1.09, 0.87]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 61786.2
        )
    }
}
