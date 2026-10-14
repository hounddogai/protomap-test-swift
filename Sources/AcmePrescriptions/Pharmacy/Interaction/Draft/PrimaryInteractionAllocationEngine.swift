import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary interaction allocation calculation.
    protocol PrimaryInteractionAllocationModifier {
        func describe() -> String
        func adjust(_ item: PrimaryInteractionAllocation, value: Double) -> Double
    }

    final class PercentPrimaryInteractionAllocationAdjuster: PrimaryInteractionAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryInteractionAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryInteractionAllocationWeightOffsetAdjuster: PrimaryInteractionAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: PrimaryInteractionAllocation, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class CapPrimaryInteractionAllocationAdjuster: PrimaryInteractionAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryInteractionAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary interaction allocation steps in order and keeps a trace of each.
    final class PrimaryInteractionAllocationEngine {
        var steps: [any PrimaryInteractionAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryInteractionAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryInteractionAllocation) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryInteractionAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryInteractionAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryInteractionAllocationEngine() -> PrimaryInteractionAllocationEngine {
        return PrimaryInteractionAllocationEngine(
            steps: [
                PercentPrimaryInteractionAllocationAdjuster(percent: 9.0),
                PrimaryInteractionAllocationWeightOffsetAdjuster(weight: 1.01),
                CapPrimaryInteractionAllocationAdjuster(cap: 8349.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 36356.0
        )
    }
}
