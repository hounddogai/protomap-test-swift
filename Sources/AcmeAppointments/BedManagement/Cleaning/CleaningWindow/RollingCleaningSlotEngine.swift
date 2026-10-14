import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling cleaning slot calculation.
    protocol RollingCleaningSlotStep {
        func describe() -> String
        func adjust(_ item: RollingCleaningSlot, value: Double) -> Double
    }

    final class FacilityRollingCleaningSlotAdjuster: RollingCleaningSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RollingCleaningSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRollingCleaningSlotAdjuster: RollingCleaningSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCleaningSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRollingCleaningSlotAdjuster: RollingCleaningSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingCleaningSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the rolling cleaning slot steps in order and keeps a trace of each.
    final class RollingCleaningSlotEngine {
        var steps: [any RollingCleaningSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCleaningSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingCleaningSlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingCleaningSlotStep = steps[index]
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

        func evaluateAll(_ items: [RollingCleaningSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingCleaningSlotEngine() -> RollingCleaningSlotEngine {
        return RollingCleaningSlotEngine(
            steps: [
                FacilityRollingCleaningSlotAdjuster(factors: ["north": 0.97, "retail": 0.76, "central": 1.16]),
                CapRollingCleaningSlotAdjuster(cap: 33662.0),
                TieredRollingCleaningSlotAdjuster(
                    bounds: [1547.0, 3836.0, 5141.0, 9910.0],
                    rates: [1.08, 1.07, 0.87, 1.01]
                ),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 79312.5
        )
    }
}
