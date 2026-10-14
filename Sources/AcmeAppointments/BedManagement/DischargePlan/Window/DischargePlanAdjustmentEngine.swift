import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan adjustment calculation.
    protocol DischargePlanAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: DischargePlanAdjustment, value: Double) -> Double
    }

    final class TieredDischargePlanAdjustmentAdjuster: DischargePlanAdjustmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDischargePlanAdjustmentAdjuster: DischargePlanAdjustmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDischargePlanAdjustmentAdjuster: DischargePlanAdjustmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DischargePlanAdjustmentLimitOffsetAdjuster: DischargePlanAdjustmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: DischargePlanAdjustment, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the discharge plan adjustment steps in order and keeps a trace of each.
    final class DischargePlanAdjustmentEngine {
        var steps: [any DischargePlanAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanAdjustment) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanAdjustmentFactor = steps[index]
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

        func evaluateAll(_ items: [DischargePlanAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanAdjustmentEngine() -> DischargePlanAdjustmentEngine {
        return DischargePlanAdjustmentEngine(
            steps: [
                TieredDischargePlanAdjustmentAdjuster(bounds: [4038.0, 5653.0, 7380.0], rates: [0.83, 1.0, 0.92]),
                CapDischargePlanAdjustmentAdjuster(cap: 3153.0),
                PercentDischargePlanAdjustmentAdjuster(percent: -21.9),
                DischargePlanAdjustmentLimitOffsetAdjuster(weight: 1.91),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 13199.6
        )
    }
}
