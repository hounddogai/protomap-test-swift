import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional eligibility slot calculation.
    protocol RegionalEligibilitySlotFactor {
        func describe() -> String
        func adjust(_ item: RegionalEligibilitySlot, value: Double) -> Double
    }

    final class CapRegionalEligibilitySlotAdjuster: RegionalEligibilitySlotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalEligibilitySlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRegionalEligibilitySlotAdjuster: RegionalEligibilitySlotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalEligibilitySlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRegionalEligibilitySlotAdjuster: RegionalEligibilitySlotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalEligibilitySlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional eligibility slot steps in order and keeps a trace of each.
    final class RegionalEligibilitySlotEngine {
        var steps: [any RegionalEligibilitySlotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalEligibilitySlotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalEligibilitySlot) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalEligibilitySlotFactor = steps[index]
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

        func evaluateAll(_ items: [RegionalEligibilitySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalEligibilitySlotEngine() -> RegionalEligibilitySlotEngine {
        return RegionalEligibilitySlotEngine(
            steps: [
                CapRegionalEligibilitySlotAdjuster(cap: 46615.0),
                RoundingRegionalEligibilitySlotAdjuster(step: 0.05),
                PercentRegionalEligibilitySlotAdjuster(percent: -4.8),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 88163.3
        )
    }
}
