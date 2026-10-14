import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial slot calculation.
    protocol DenialSlotModifier {
        func describe() -> String
        func adjust(_ item: DenialSlot, value: Double) -> Double
    }

    final class MinimumDenialSlotAdjuster: DenialSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDenialSlotAdjuster: DenialSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionDenialSlotAdjuster: DenialSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: DenialSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDenialSlotAdjuster: DenialSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DenialSlotCapacityOffsetAdjuster: DenialSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: DenialSlot, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the denial slot steps in order and keeps a trace of each.
    final class DenialSlotEngine {
        var steps: [any DenialSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DenialSlot) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialSlotModifier = steps[index]
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

        func evaluateAll(_ items: [DenialSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDenialSlotEngine() -> DenialSlotEngine {
        return DenialSlotEngine(
            steps: [
                MinimumDenialSlotAdjuster(minimum: 38.3),
                RoundingDenialSlotAdjuster(step: 0.1),
                RegionDenialSlotAdjuster(factors: ["online": 1.3, "central": 1.27, "west": 1.0]),
                TieredDenialSlotAdjuster(bounds: [1690.0, 6268.0, 6317.0], rates: [0.97, 0.88, 1.16]),
                DenialSlotCapacityOffsetAdjuster(weight: 0.29),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 73056.6
        )
    }
}
