import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the pending formulary allocation calculation.
    protocol PendingFormularyAllocationFactor {
        func describe() -> String
        func adjust(_ item: PendingFormularyAllocation, value: Double) -> Double
    }

    final class RoundingPendingFormularyAllocationAdjuster: PendingFormularyAllocationFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingFormularyAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitlePendingFormularyAllocationAdjuster: PendingFormularyAllocationFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PendingFormularyAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PendingFormularyAllocationMarginOffsetAdjuster: PendingFormularyAllocationFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: PendingFormularyAllocation, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class PercentPendingFormularyAllocationAdjuster: PendingFormularyAllocationFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingFormularyAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending formulary allocation steps in order and keeps a trace of each.
    final class PendingFormularyAllocationEngine {
        var steps: [any PendingFormularyAllocationFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFormularyAllocationFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingFormularyAllocation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFormularyAllocationFactor = steps[index]
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

        func evaluateAll(_ items: [PendingFormularyAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingFormularyAllocationEngine() -> PendingFormularyAllocationEngine {
        return PendingFormularyAllocationEngine(
            steps: [
                RoundingPendingFormularyAllocationAdjuster(step: 0.1),
                TitlePendingFormularyAllocationAdjuster(factors: ["central": 0.9, "north": 0.88]),
                PendingFormularyAllocationMarginOffsetAdjuster(weight: 1.86),
                PercentPendingFormularyAllocationAdjuster(percent: -16.1),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 71459.0
        )
    }
}
