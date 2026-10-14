import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending statement slot calculation.
    protocol PendingStatementSlotStep {
        func describe() -> String
        func adjust(_ item: PendingStatementSlot, value: Double) -> Double
    }

    final class MinimumPendingStatementSlotAdjuster: PendingStatementSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingStatementSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityPendingStatementSlotAdjuster: PendingStatementSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: PendingStatementSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPendingStatementSlotAdjuster: PendingStatementSlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingStatementSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingStatementSlotAdjuster: PendingStatementSlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingStatementSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPendingStatementSlotAdjuster: PendingStatementSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingStatementSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingStatementSlotMarginOffsetAdjuster: PendingStatementSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: PendingStatementSlot, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the pending statement slot steps in order and keeps a trace of each.
    final class PendingStatementSlotEngine {
        var steps: [any PendingStatementSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingStatementSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingStatementSlot) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingStatementSlotStep = steps[index]
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

        func evaluateAll(_ items: [PendingStatementSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingStatementSlotEngine() -> PendingStatementSlotEngine {
        return PendingStatementSlotEngine(
            steps: [
                MinimumPendingStatementSlotAdjuster(minimum: 30.1),
                FacilityPendingStatementSlotAdjuster(factors: ["south": 1.11]),
                PercentPendingStatementSlotAdjuster(percent: -18.3),
                RoundingPendingStatementSlotAdjuster(step: 0.1),
                CapPendingStatementSlotAdjuster(cap: 20588.0),
                PendingStatementSlotMarginOffsetAdjuster(weight: 1.34),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 97536.6
        )
    }
}
