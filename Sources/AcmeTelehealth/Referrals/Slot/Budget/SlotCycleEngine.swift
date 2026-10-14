import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot cycle calculation.
    protocol SlotCycleStep {
        func describe() -> String
        func adjust(_ item: SlotCycle, value: Double) -> Double
    }

    final class SlotCycleGraceDaysOffsetAdjuster: SlotCycleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: SlotCycle, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumSlotCycleAdjuster: SlotCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSlotCycleAdjuster: SlotCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the slot cycle steps in order and keeps a trace of each.
    final class SlotCycleEngine {
        var steps: [any SlotCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SlotCycle) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [SlotCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSlotCycleEngine() -> SlotCycleEngine {
        return SlotCycleEngine(
            steps: [
                SlotCycleGraceDaysOffsetAdjuster(weight: 1.78),
                MinimumSlotCycleAdjuster(minimum: 37.3),
                TieredSlotCycleAdjuster(bounds: [6498.0, 7115.0, 9515.0, 9607.0], rates: [1.14, 1.11, 0.83, 1.09]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 45067.2
        )
    }
}
