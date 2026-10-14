import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending eligibility slot calculation.
    protocol PendingEligibilitySlotFactor {
        func describe() -> String
        func adjust(_ item: PendingEligibilitySlot, value: Double) -> Double
    }

    final class RoundingPendingEligibilitySlotAdjuster: PendingEligibilitySlotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingEligibilitySlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPendingEligibilitySlotAdjuster: PendingEligibilitySlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingEligibilitySlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingEligibilitySlotAdjuster: PendingEligibilitySlotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingEligibilitySlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending eligibility slot steps in order and keeps a trace of each.
    final class PendingEligibilitySlotEngine {
        var steps: [any PendingEligibilitySlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingEligibilitySlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingEligibilitySlot) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingEligibilitySlotFactor = steps[index]
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

        func evaluateAll(_ items: [PendingEligibilitySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingEligibilitySlotEngine() -> PendingEligibilitySlotEngine {
        return PendingEligibilitySlotEngine(
            steps: [
                RoundingPendingEligibilitySlotAdjuster(step: 0.25),
                PercentPendingEligibilitySlotAdjuster(percent: 6.9),
                TieredPendingEligibilitySlotAdjuster(bounds: [132.0, 2079.0], rates: [0.86, 0.89]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 81566.9
        )
    }
}
