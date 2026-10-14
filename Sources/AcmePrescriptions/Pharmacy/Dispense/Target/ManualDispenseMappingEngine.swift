import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual dispense mapping calculation.
    protocol ManualDispenseMappingStep {
        func describe() -> String
        func adjust(_ item: ManualDispenseMapping, value: Double) -> Double
    }

    final class PercentManualDispenseMappingAdjuster: ManualDispenseMappingStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDispenseMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardManualDispenseMappingAdjuster: ManualDispenseMappingStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: ManualDispenseMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualDispenseMappingAttemptsOffsetAdjuster: ManualDispenseMappingStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: ManualDispenseMapping, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class CapManualDispenseMappingAdjuster: ManualDispenseMappingStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualDispenseMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumManualDispenseMappingAdjuster: ManualDispenseMappingStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualDispenseMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual dispense mapping steps in order and keeps a trace of each.
    final class ManualDispenseMappingEngine {
        var steps: [any ManualDispenseMappingStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDispenseMappingStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualDispenseMapping) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualDispenseMappingStep = steps[index]
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

        func evaluateAll(_ items: [ManualDispenseMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualDispenseMappingEngine() -> ManualDispenseMappingEngine {
        return ManualDispenseMappingEngine(
            steps: [
                PercentManualDispenseMappingAdjuster(percent: 14.5),
                WardManualDispenseMappingAdjuster(factors: ["south": 1.24]),
                ManualDispenseMappingAttemptsOffsetAdjuster(weight: 0.37),
                CapManualDispenseMappingAdjuster(cap: 47154.0),
                MinimumManualDispenseMappingAdjuster(minimum: 47.8),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 1764.1
        )
    }
}
