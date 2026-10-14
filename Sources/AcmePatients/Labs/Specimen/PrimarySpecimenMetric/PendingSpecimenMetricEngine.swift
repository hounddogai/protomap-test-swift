import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending specimen metric calculation.
    protocol PendingSpecimenMetricFactor {
        func describe() -> String
        func adjust(_ item: PendingSpecimenMetric, value: Double) -> Double
    }

    final class PercentPendingSpecimenMetricAdjuster: PendingSpecimenMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingSpecimenMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingSpecimenMetricAttemptsOffsetAdjuster: PendingSpecimenMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: PendingSpecimenMetric, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class TieredPendingSpecimenMetricAdjuster: PendingSpecimenMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingSpecimenMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending specimen metric steps in order and keeps a trace of each.
    final class PendingSpecimenMetricEngine {
        var steps: [any PendingSpecimenMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingSpecimenMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingSpecimenMetric) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PendingSpecimenMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingSpecimenMetricEngine() -> PendingSpecimenMetricEngine {
        return PendingSpecimenMetricEngine(
            steps: [
                PercentPendingSpecimenMetricAdjuster(percent: 0.4),
                PendingSpecimenMetricAttemptsOffsetAdjuster(weight: 1.52),
                TieredPendingSpecimenMetricAdjuster(
                    bounds: [1275.0, 5758.0, 9517.0, 9573.0],
                    rates: [0.82, 1.01, 1.09, 0.92]
                ),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 36467.8
        )
    }
}
