import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority allocation calculation.
    protocol PriorityAllocationModifier {
        func describe() -> String
        func adjust(_ item: PriorityAllocation, value: Double) -> Double
    }

    final class FlaggedPriorityAllocationAdjuster: PriorityAllocationModifier {
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

        func adjust(_ item: PriorityAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPriorityAllocationAdjuster: PriorityAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PriorityAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PriorityAllocationCopayOffsetAdjuster: PriorityAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: PriorityAllocation, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentPriorityAllocationAdjuster: PriorityAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitlePriorityAllocationAdjuster: PriorityAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PriorityAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the priority allocation steps in order and keeps a trace of each.
    final class PriorityAllocationEngine {
        var steps: [any PriorityAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PriorityAllocation) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PriorityAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [PriorityAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPriorityAllocationEngine(_ flags: Kit.Flags.Registry) -> PriorityAllocationEngine {
        return PriorityAllocationEngine(
            steps: [
                FlaggedPriorityAllocationAdjuster(flags: flags, flag: "priority-allocation-pending", percent: -8.5),
                RoundingPriorityAllocationAdjuster(step: 5.0),
                PriorityAllocationCopayOffsetAdjuster(weight: 0.21),
                PercentPriorityAllocationAdjuster(percent: -2.9),
                TitlePriorityAllocationAdjuster(factors: ["west": 1.28, "east": 0.8]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 67228.3
        )
    }
}
