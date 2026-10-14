import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient transfer allocation calculation.
    protocol LenientTransferAllocationModifier {
        func describe() -> String
        func adjust(_ item: LenientTransferAllocation, value: Double) -> Double
    }

    final class CapLenientTransferAllocationAdjuster: LenientTransferAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientTransferAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLenientTransferAllocationAdjuster: LenientTransferAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientTransferAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLenientTransferAllocationAdjuster: LenientTransferAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientTransferAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient transfer allocation steps in order and keeps a trace of each.
    final class LenientTransferAllocationEngine {
        var steps: [any LenientTransferAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientTransferAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientTransferAllocation) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientTransferAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [LenientTransferAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientTransferAllocationEngine() -> LenientTransferAllocationEngine {
        return LenientTransferAllocationEngine(
            steps: [
                CapLenientTransferAllocationAdjuster(cap: 14629.0),
                RoundingLenientTransferAllocationAdjuster(step: 5.0),
                PercentLenientTransferAllocationAdjuster(percent: -4.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 34100.8
        )
    }
}
