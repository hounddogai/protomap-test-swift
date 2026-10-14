import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality allocation calculation.
    protocol ModalityAllocationModifier {
        func describe() -> String
        func adjust(_ item: ModalityAllocation, value: Double) -> Double
    }

    final class FlaggedModalityAllocationAdjuster: ModalityAllocationModifier {
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

        func adjust(_ item: ModalityAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapModalityAllocationAdjuster: ModalityAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ModalityAllocationBatchSizeOffsetAdjuster: ModalityAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ModalityAllocation, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class PercentModalityAllocationAdjuster: ModalityAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingModalityAllocationAdjuster: ModalityAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumModalityAllocationAdjuster: ModalityAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the modality allocation steps in order and keeps a trace of each.
    final class ModalityAllocationEngine {
        var steps: [any ModalityAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ModalityAllocation) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [ModalityAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultModalityAllocationEngine(_ flags: Kit.Flags.Registry) -> ModalityAllocationEngine {
        return ModalityAllocationEngine(
            steps: [
                FlaggedModalityAllocationAdjuster(flags: flags, flag: "modality-allocation-seasonal", percent: -3.9),
                CapModalityAllocationAdjuster(cap: 14807.0),
                ModalityAllocationBatchSizeOffsetAdjuster(weight: 1.24),
                PercentModalityAllocationAdjuster(percent: -10.4),
                RoundingModalityAllocationAdjuster(step: 0.25),
                MinimumModalityAllocationAdjuster(minimum: 27.4),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 17067.9
        )
    }
}
