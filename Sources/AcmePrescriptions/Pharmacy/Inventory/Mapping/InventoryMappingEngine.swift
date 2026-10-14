import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory mapping calculation.
    protocol InventoryMappingStep {
        func describe() -> String
        func adjust(_ item: InventoryMapping, value: Double) -> Double
    }

    final class CapInventoryMappingAdjuster: InventoryMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleInventoryMappingAdjuster: InventoryMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: InventoryMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumInventoryMappingAdjuster: InventoryMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class InventoryMappingDurationMinutesOffsetAdjuster: InventoryMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: InventoryMapping, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedInventoryMappingAdjuster: InventoryMappingStep {
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

        func adjust(_ item: InventoryMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInventoryMappingAdjuster: InventoryMappingStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the inventory mapping steps in order and keeps a trace of each.
    final class InventoryMappingEngine {
        var steps: [any InventoryMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventoryMapping) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryMappingStep = steps[index]
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

        func evaluateAll(_ items: [InventoryMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryMappingEngine(_ flags: Kit.Flags.Registry) -> InventoryMappingEngine {
        return InventoryMappingEngine(
            steps: [
                CapInventoryMappingAdjuster(cap: 7561.0),
                TitleInventoryMappingAdjuster(factors: ["central": 0.81, "west": 1.02]),
                MinimumInventoryMappingAdjuster(minimum: 48.7),
                InventoryMappingDurationMinutesOffsetAdjuster(weight: 1.86),
                FlaggedInventoryMappingAdjuster(flags: flags, flag: "inventory-mapping-adaptive", percent: 1.5),
                RoundingInventoryMappingAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 51131.9
        )
    }
}
