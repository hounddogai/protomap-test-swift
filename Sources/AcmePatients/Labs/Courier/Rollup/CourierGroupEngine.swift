import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier group calculation.
    protocol CourierGroupModifier {
        func describe() -> String
        func adjust(_ item: CourierGroup, value: Double) -> Double
    }

    final class RoundingCourierGroupAdjuster: CourierGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumCourierGroupAdjuster: CourierGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CourierGroupWeightOffsetAdjuster: CourierGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: CourierGroup, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class TieredCourierGroupAdjuster: CourierGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the courier group steps in order and keeps a trace of each.
    final class CourierGroupEngine {
        var steps: [any CourierGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CourierGroup) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierGroupModifier = steps[index]
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

        func evaluateAll(_ items: [CourierGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCourierGroupEngine() -> CourierGroupEngine {
        return CourierGroupEngine(
            steps: [
                RoundingCourierGroupAdjuster(step: 1.0),
                MinimumCourierGroupAdjuster(minimum: 38.1),
                CourierGroupWeightOffsetAdjuster(weight: 1.88),
                TieredCourierGroupAdjuster(bounds: [3809.0, 6443.0, 9580.0], rates: [0.9, 0.86, 0.99]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 86392.5
        )
    }
}
