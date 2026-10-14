import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense allocation calculation.
    protocol DispenseAllocationFactor {
        func describe() -> String
        func adjust(_ item: DispenseAllocation, value: Double) -> Double
    }

    final class FlaggedDispenseAllocationAdjuster: DispenseAllocationFactor {
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

        func adjust(_ item: DispenseAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDispenseAllocationAdjuster: DispenseAllocationFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispenseAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DispenseAllocationUpdatedAtOffsetAdjuster: DispenseAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: DispenseAllocation, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the dispense allocation steps in order and keeps a trace of each.
    final class DispenseAllocationEngine {
        var steps: [any DispenseAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DispenseAllocation) -> Double {
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

        func evaluateAll(_ items: [DispenseAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDispenseAllocationEngine(_ flags: Kit.Flags.Registry) -> DispenseAllocationEngine {
        return DispenseAllocationEngine(
            steps: [
                FlaggedDispenseAllocationAdjuster(flags: flags, flag: "dispense-allocation-pending", percent: 5.3),
                MinimumDispenseAllocationAdjuster(minimum: 5.9),
                DispenseAllocationUpdatedAtOffsetAdjuster(weight: 0.14),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 81305.1
        )
    }
}
