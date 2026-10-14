import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending result slot calculation.
    protocol PendingResultSlotModifier {
        func describe() -> String
        func adjust(_ item: PendingResultSlot, value: Double) -> Double
    }

    final class TieredPendingResultSlotAdjuster: PendingResultSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingResultSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingResultSlotDiscountOffsetAdjuster: PendingResultSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: PendingResultSlot, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CapPendingResultSlotAdjuster: PendingResultSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingResultSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPendingResultSlotAdjuster: PendingResultSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingResultSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingResultSlotAdjuster: PendingResultSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingResultSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPendingResultSlotAdjuster: PendingResultSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingResultSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending result slot steps in order and keeps a trace of each.
    final class PendingResultSlotEngine {
        var steps: [any PendingResultSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingResultSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingResultSlot) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingResultSlotModifier = steps[index]
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

        func evaluateAll(_ items: [PendingResultSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingResultSlotEngine() -> PendingResultSlotEngine {
        return PendingResultSlotEngine(
            steps: [
                TieredPendingResultSlotAdjuster(
                    bounds: [907.0, 4273.0, 7442.0, 8893.0],
                    rates: [1.05, 1.18, 1.17, 1.04]
                ),
                PendingResultSlotDiscountOffsetAdjuster(weight: 1.46),
                CapPendingResultSlotAdjuster(cap: 30108.0),
                PercentPendingResultSlotAdjuster(percent: 6.2),
                RoundingPendingResultSlotAdjuster(step: 0.1),
                MinimumPendingResultSlotAdjuster(minimum: 46.3),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 69799.3
        )
    }
}
