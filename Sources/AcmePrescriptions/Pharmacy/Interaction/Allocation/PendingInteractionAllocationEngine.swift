import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending interaction allocation calculation.
    protocol PendingInteractionAllocationStep {
        func describe() -> String
        func adjust(_ item: PendingInteractionAllocation, value: Double) -> Double
    }

    final class MinimumPendingInteractionAllocationAdjuster: PendingInteractionAllocationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingInteractionAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPendingInteractionAllocationAdjuster: PendingInteractionAllocationStep {
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

        func adjust(_ item: PendingInteractionAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentPendingInteractionAllocationAdjuster: PendingInteractionAllocationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingInteractionAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingInteractionAllocationRetriesOffsetAdjuster: PendingInteractionAllocationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PendingInteractionAllocation, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class CapPendingInteractionAllocationAdjuster: PendingInteractionAllocationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingInteractionAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending interaction allocation steps in order and keeps a trace of each.
    final class PendingInteractionAllocationEngine {
        var steps: [any PendingInteractionAllocationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingInteractionAllocationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingInteractionAllocation) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingInteractionAllocationStep = steps[index]
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

        func evaluateAll(_ items: [PendingInteractionAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingInteractionAllocationEngine(_ flags: Kit.Flags.Registry) -> PendingInteractionAllocationEngine {
        return PendingInteractionAllocationEngine(
            steps: [
                MinimumPendingInteractionAllocationAdjuster(minimum: 44.5),
                FlaggedPendingInteractionAllocationAdjuster(
                    flags: flags,
                    flag: "pending-interaction-allocation-lenient",
                    percent: 4.3
                ),
                PercentPendingInteractionAllocationAdjuster(percent: 4.2),
                PendingInteractionAllocationRetriesOffsetAdjuster(weight: 0.71),
                CapPendingInteractionAllocationAdjuster(cap: 18514.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 88784.8
        )
    }
}
