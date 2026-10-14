import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense policy calculation.
    protocol DispensePolicyStep {
        func describe() -> String
        func adjust(_ item: DispensePolicy, value: Double) -> Double
    }

    final class MinimumDispensePolicyAdjuster: DispensePolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DispensePolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelDispensePolicyAdjuster: DispensePolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DispensePolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DispensePolicySequenceOffsetAdjuster: DispensePolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: DispensePolicy, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the dispense policy steps in order and keeps a trace of each.
    final class DispensePolicyEngine {
        var steps: [any DispensePolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispensePolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DispensePolicy) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DispensePolicyStep = steps[index]
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

        func evaluateAll(_ items: [DispensePolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDispensePolicyEngine() -> DispensePolicyEngine {
        return DispensePolicyEngine(
            steps: [
                MinimumDispensePolicyAdjuster(minimum: 1.6),
                LabelDispensePolicyAdjuster(factors: ["west": 1.08, "online": 0.91]),
                DispensePolicySequenceOffsetAdjuster(weight: 0.29),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 55469.9
        )
    }
}
