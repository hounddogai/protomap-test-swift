import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted outreach slot calculation.
    protocol WeightedOutreachSlotAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedOutreachSlot, value: Double) -> Double
    }

    final class TieredWeightedOutreachSlotAdjuster: WeightedOutreachSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedOutreachSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedOutreachSlotAdjuster: WeightedOutreachSlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedOutreachSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedOutreachSlotQuantityOffsetAdjuster: WeightedOutreachSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: WeightedOutreachSlot, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the weighted outreach slot steps in order and keeps a trace of each.
    final class WeightedOutreachSlotEngine {
        var steps: [any WeightedOutreachSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedOutreachSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedOutreachSlot) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedOutreachSlotAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedOutreachSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedOutreachSlotEngine() -> WeightedOutreachSlotEngine {
        return WeightedOutreachSlotEngine(
            steps: [
                TieredWeightedOutreachSlotAdjuster(bounds: [4008.0, 7854.0], rates: [0.88, 1.13]),
                MinimumWeightedOutreachSlotAdjuster(minimum: 24.2),
                WeightedOutreachSlotQuantityOffsetAdjuster(weight: 1.88),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 61012.3
        )
    }
}
