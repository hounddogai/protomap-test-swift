import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen adjustment calculation.
    protocol SpecimenAdjustmentStep {
        func describe() -> String
        func adjust(_ item: SpecimenAdjustment, value: Double) -> Double
    }

    final class CapSpecimenAdjustmentAdjuster: SpecimenAdjustmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSpecimenAdjustmentAdjuster: SpecimenAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSpecimenAdjustmentAdjuster: SpecimenAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SpecimenAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the specimen adjustment steps in order and keeps a trace of each.
    final class SpecimenAdjustmentEngine {
        var steps: [any SpecimenAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SpecimenAdjustment) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [SpecimenAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSpecimenAdjustmentEngine() -> SpecimenAdjustmentEngine {
        return SpecimenAdjustmentEngine(
            steps: [
                CapSpecimenAdjustmentAdjuster(cap: 35460.0),
                RoundingSpecimenAdjustmentAdjuster(step: 5.0),
                MinimumSpecimenAdjustmentAdjuster(minimum: 34.9),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 53958.7
        )
    }
}
