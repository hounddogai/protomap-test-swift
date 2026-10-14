import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim slot calculation.
    protocol ClaimSlotStep {
        func describe() -> String
        func adjust(_ item: ClaimSlot, value: Double) -> Double
    }

    final class CapClaimSlotAdjuster: ClaimSlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredClaimSlotAdjuster: ClaimSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ClaimSlotUpdatedAtOffsetAdjuster: ClaimSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: ClaimSlot, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class PercentClaimSlotAdjuster: ClaimSlotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClaimSlotAdjuster: ClaimSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelClaimSlotAdjuster: ClaimSlotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ClaimSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the claim slot steps in order and keeps a trace of each.
    final class ClaimSlotEngine {
        var steps: [any ClaimSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimSlot) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimSlotStep = steps[index]
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

        func evaluateAll(_ items: [ClaimSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimSlotEngine() -> ClaimSlotEngine {
        return ClaimSlotEngine(
            steps: [
                CapClaimSlotAdjuster(cap: 33690.0),
                TieredClaimSlotAdjuster(bounds: [3418.0, 4078.0, 8220.0, 8394.0], rates: [0.86, 0.99, 1.08, 0.99]),
                ClaimSlotUpdatedAtOffsetAdjuster(weight: 0.07),
                PercentClaimSlotAdjuster(percent: -16.3),
                MinimumClaimSlotAdjuster(minimum: 25.7),
                LabelClaimSlotAdjuster(factors: ["south": 0.74, "retail": 1.1, "west": 1.4]),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 73131.7
        )
    }
}
