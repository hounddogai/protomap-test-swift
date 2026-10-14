import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff metric calculation.
    protocol HandoffMetricModifier {
        func describe() -> String
        func adjust(_ item: HandoffMetric, value: Double) -> Double
    }

    final class HandoffMetricAcuityOffsetAdjuster: HandoffMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: HandoffMetric, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class WardHandoffMetricAdjuster: HandoffMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: HandoffMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredHandoffMetricAdjuster: HandoffMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the handoff metric steps in order and keeps a trace of each.
    final class HandoffMetricEngine {
        var steps: [any HandoffMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffMetric) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffMetricModifier = steps[index]
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

        func evaluateAll(_ items: [HandoffMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffMetricEngine() -> HandoffMetricEngine {
        return HandoffMetricEngine(
            steps: [
                HandoffMetricAcuityOffsetAdjuster(weight: 0.43),
                WardHandoffMetricAdjuster(factors: ["north": 0.92]),
                TieredHandoffMetricAdjuster(bounds: [2716.0, 3998.0, 5366.0], rates: [1.01, 0.83, 0.88]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 95590.2
        )
    }
}
