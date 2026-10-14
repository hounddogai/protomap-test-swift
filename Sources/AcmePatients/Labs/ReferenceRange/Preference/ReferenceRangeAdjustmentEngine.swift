import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range adjustment calculation.
    protocol ReferenceRangeAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeAdjustment, value: Double) -> Double
    }

    final class TieredReferenceRangeAdjustmentAdjuster: ReferenceRangeAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapReferenceRangeAdjustmentAdjuster: ReferenceRangeAdjustmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitReferenceRangeAdjustmentAdjuster: ReferenceRangeAdjustmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ReferenceRangeAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the reference range adjustment steps in order and keeps a trace of each.
    final class ReferenceRangeAdjustmentEngine {
        var steps: [any ReferenceRangeAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeAdjustment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeAdjustmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeAdjustmentEngine() -> ReferenceRangeAdjustmentEngine {
        return ReferenceRangeAdjustmentEngine(
            steps: [
                TieredReferenceRangeAdjustmentAdjuster(bounds: [3552.0, 5794.0], rates: [0.91, 0.86]),
                CapReferenceRangeAdjustmentAdjuster(cap: 45058.0),
                UnitReferenceRangeAdjustmentAdjuster(factors: ["central": 1.14]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 74544.3
        )
    }
}
