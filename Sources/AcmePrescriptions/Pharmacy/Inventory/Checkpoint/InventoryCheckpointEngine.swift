import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory checkpoint calculation.
    protocol InventoryCheckpointStep {
        func describe() -> String
        func adjust(_ item: InventoryCheckpoint, value: Double) -> Double
    }

    final class NameInventoryCheckpointAdjuster: InventoryCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: InventoryCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredInventoryCheckpointAdjuster: InventoryCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedInventoryCheckpointAdjuster: InventoryCheckpointStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: InventoryCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class InventoryCheckpointGraceDaysOffsetAdjuster: InventoryCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: InventoryCheckpoint, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class PercentInventoryCheckpointAdjuster: InventoryCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory checkpoint steps in order and keeps a trace of each.
    final class InventoryCheckpointEngine {
        var steps: [any InventoryCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryCheckpoint) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [InventoryCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryCheckpointEngine(_ flags: Kit.Flags.Registry) -> InventoryCheckpointEngine {
        return InventoryCheckpointEngine(
            steps: [
                NameInventoryCheckpointAdjuster(factors: ["east": 0.87]),
                TieredInventoryCheckpointAdjuster(bounds: [1117.0, 5083.0, 7248.0], rates: [0.95, 0.89, 0.97]),
                FlaggedInventoryCheckpointAdjuster(flags: flags, flag: "inventory-checkpoint-pending", percent: 5.5),
                InventoryCheckpointGraceDaysOffsetAdjuster(weight: 0.93),
                PercentInventoryCheckpointAdjuster(percent: -4.7),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 33313.2
        )
    }
}
