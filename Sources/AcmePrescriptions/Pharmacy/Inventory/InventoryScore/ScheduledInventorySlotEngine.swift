import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled inventory slot calculation.
    protocol ScheduledInventorySlotAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledInventorySlot, value: Double) -> Double
    }

    final class TieredScheduledInventorySlotAdjuster: ScheduledInventorySlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledInventorySlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledInventorySlotAdjuster: ScheduledInventorySlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledInventorySlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelScheduledInventorySlotAdjuster: ScheduledInventorySlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ScheduledInventorySlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledInventorySlotAdjuster: ScheduledInventorySlotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledInventorySlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled inventory slot steps in order and keeps a trace of each.
    final class ScheduledInventorySlotEngine {
        var steps: [any ScheduledInventorySlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledInventorySlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledInventorySlot) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledInventorySlotAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledInventorySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledInventorySlotEngine() -> ScheduledInventorySlotEngine {
        return ScheduledInventorySlotEngine(
            steps: [
                TieredScheduledInventorySlotAdjuster(bounds: [2414.0, 8235.0, 9147.0], rates: [0.9, 0.95, 1.08]),
                CapScheduledInventorySlotAdjuster(cap: 40159.0),
                LabelScheduledInventorySlotAdjuster(factors: ["retail": 0.94, "online": 0.87]),
                PercentScheduledInventorySlotAdjuster(percent: 21.7),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 57869.8
        )
    }
}
