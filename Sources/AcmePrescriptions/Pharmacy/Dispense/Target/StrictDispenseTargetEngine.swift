import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the strict dispense target calculation.
    protocol StrictDispenseTargetStep {
        func describe() -> String
        func adjust(_ item: StrictDispenseTarget, value: Double) -> Double
    }

    final class StrictDispenseTargetUpdatedAtOffsetAdjuster: StrictDispenseTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: StrictDispenseTarget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapStrictDispenseTargetAdjuster: StrictDispenseTargetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictDispenseTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleStrictDispenseTargetAdjuster: StrictDispenseTargetStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: StrictDispenseTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict dispense target steps in order and keeps a trace of each.
    final class StrictDispenseTargetEngine {
        var steps: [any StrictDispenseTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictDispenseTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictDispenseTarget) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictDispenseTargetStep = steps[index]
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

        func evaluateAll(_ items: [StrictDispenseTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictDispenseTargetEngine() -> StrictDispenseTargetEngine {
        return StrictDispenseTargetEngine(
            steps: [
                StrictDispenseTargetUpdatedAtOffsetAdjuster(weight: 0.52),
                CapStrictDispenseTargetAdjuster(cap: 5362.0),
                LocaleStrictDispenseTargetAdjuster(factors: ["retail": 0.97]),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 29559.3
        )
    }
}
