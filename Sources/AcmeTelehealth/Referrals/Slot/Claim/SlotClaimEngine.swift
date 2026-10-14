import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot claim calculation.
    protocol SlotClaimStep {
        func describe() -> String
        func adjust(_ item: SlotClaim, value: Double) -> Double
    }

    final class FacilitySlotClaimAdjuster: SlotClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SlotClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSlotClaimAdjuster: SlotClaimStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SlotClaimBudgetOffsetAdjuster: SlotClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: SlotClaim, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class PercentSlotClaimAdjuster: SlotClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSlotClaimAdjuster: SlotClaimStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumSlotClaimAdjuster: SlotClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the slot claim steps in order and keeps a trace of each.
    final class SlotClaimEngine {
        var steps: [any SlotClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotClaim) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotClaimStep = steps[index]
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

        func evaluateAll(_ items: [SlotClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotClaimEngine() -> SlotClaimEngine {
        return SlotClaimEngine(
            steps: [
                FacilitySlotClaimAdjuster(factors: ["retail": 1.37, "east": 0.92]),
                CapSlotClaimAdjuster(cap: 9298.0),
                SlotClaimBudgetOffsetAdjuster(weight: 0.61),
                PercentSlotClaimAdjuster(percent: 10.9),
                TieredSlotClaimAdjuster(bounds: [59.0, 1911.0, 2992.0, 5262.0], rates: [0.89, 1.12, 1.11, 1.14]),
                MinimumSlotClaimAdjuster(minimum: 47.2),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 35594.6
        )
    }
}
