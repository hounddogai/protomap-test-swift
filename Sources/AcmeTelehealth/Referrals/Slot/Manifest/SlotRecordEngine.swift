import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot record calculation.
    protocol SlotRecordStep {
        func describe() -> String
        func adjust(_ item: SlotRecord, value: Double) -> Double
    }

    final class MinimumSlotRecordAdjuster: SlotRecordStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSlotRecordAdjuster: SlotRecordStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotRecord, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SlotRecordBudgetOffsetAdjuster: SlotRecordStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: SlotRecord, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class RoundingSlotRecordAdjuster: SlotRecordStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSlotRecordAdjuster: SlotRecordStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSlotRecordAdjuster: SlotRecordStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotRecord, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the slot record steps in order and keeps a trace of each.
    final class SlotRecordEngine {
        var steps: [any SlotRecordStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotRecordStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SlotRecord) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotRecordStep = steps[index]
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

        func evaluateAll(_ items: [SlotRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSlotRecordEngine() -> SlotRecordEngine {
        return SlotRecordEngine(
            steps: [
                MinimumSlotRecordAdjuster(minimum: 12.5),
                CapSlotRecordAdjuster(cap: 4961.0),
                SlotRecordBudgetOffsetAdjuster(weight: 0.05),
                RoundingSlotRecordAdjuster(step: 0.5),
                TieredSlotRecordAdjuster(bounds: [1904.0, 3349.0, 7751.0, 9620.0], rates: [0.84, 1.13, 1.18, 0.84]),
                PercentSlotRecordAdjuster(percent: -10.2),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 31268.4
        )
    }
}
