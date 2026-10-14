import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan tier calculation.
    protocol DischargePlanTierStep {
        func describe() -> String
        func adjust(_ item: DischargePlanTier, value: Double) -> Double
    }

    final class DischargePlanTierEndsAtOffsetAdjuster: DischargePlanTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: DischargePlanTier, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class TieredDischargePlanTierAdjuster: DischargePlanTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDischargePlanTierAdjuster: DischargePlanTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the discharge plan tier steps in order and keeps a trace of each.
    final class DischargePlanTierEngine {
        var steps: [any DischargePlanTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DischargePlanTier) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanTierStep = steps[index]
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

        func evaluateAll(_ items: [DischargePlanTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDischargePlanTierEngine() -> DischargePlanTierEngine {
        return DischargePlanTierEngine(
            steps: [
                DischargePlanTierEndsAtOffsetAdjuster(weight: 1.62),
                TieredDischargePlanTierAdjuster(bounds: [1473.0, 1800.0], rates: [0.83, 1.05]),
                CapDischargePlanTierAdjuster(cap: 15322.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 61279.4
        )
    }
}
