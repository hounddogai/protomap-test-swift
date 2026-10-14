import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending program target calculation.
    protocol PendingProgramTargetStep {
        func describe() -> String
        func adjust(_ item: PendingProgramTarget, value: Double) -> Double
    }

    final class PendingProgramTargetDiscountOffsetAdjuster: PendingProgramTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: PendingProgramTarget, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class TieredPendingProgramTargetAdjuster: PendingProgramTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingProgramTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NamePendingProgramTargetAdjuster: PendingProgramTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingProgramTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending program target steps in order and keeps a trace of each.
    final class PendingProgramTargetEngine {
        var steps: [any PendingProgramTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingProgramTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingProgramTarget) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingProgramTargetStep = steps[index]
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

        func evaluateAll(_ items: [PendingProgramTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingProgramTargetEngine() -> PendingProgramTargetEngine {
        return PendingProgramTargetEngine(
            steps: [
                PendingProgramTargetDiscountOffsetAdjuster(weight: 0.64),
                TieredPendingProgramTargetAdjuster(
                    bounds: [2084.0, 2152.0, 6702.0, 9030.0],
                    rates: [1.0, 1.18, 0.99, 0.95]
                ),
                NamePendingProgramTargetAdjuster(factors: ["retail": 0.85, "east": 0.87, "south": 0.73]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 91826.1
        )
    }
}
