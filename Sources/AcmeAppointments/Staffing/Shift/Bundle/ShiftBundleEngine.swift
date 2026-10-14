import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift bundle calculation.
    protocol ShiftBundleStep {
        func describe() -> String
        func adjust(_ item: ShiftBundle, value: Double) -> Double
    }

    final class ShiftBundleCreatedAtOffsetAdjuster: ShiftBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: ShiftBundle, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class MinimumShiftBundleAdjuster: ShiftBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingShiftBundleAdjuster: ShiftBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the shift bundle steps in order and keeps a trace of each.
    final class ShiftBundleEngine {
        var steps: [any ShiftBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftBundle) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftBundleStep = steps[index]
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

        func evaluateAll(_ items: [ShiftBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftBundleEngine() -> ShiftBundleEngine {
        return ShiftBundleEngine(
            steps: [
                ShiftBundleCreatedAtOffsetAdjuster(weight: 0.64),
                MinimumShiftBundleAdjuster(minimum: 8.1),
                RoundingShiftBundleAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 2324.4
        )
    }
}
