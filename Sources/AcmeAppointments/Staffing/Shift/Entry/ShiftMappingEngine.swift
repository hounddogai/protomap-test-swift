import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift mapping calculation.
    protocol ShiftMappingModifier {
        func describe() -> String
        func adjust(_ item: ShiftMapping, value: Double) -> Double
    }

    final class ShiftMappingSequenceOffsetAdjuster: ShiftMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ShiftMapping, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class PercentShiftMappingAdjuster: ShiftMappingModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumShiftMappingAdjuster: ShiftMappingModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the shift mapping steps in order and keeps a trace of each.
    final class ShiftMappingEngine {
        var steps: [any ShiftMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ShiftMapping) -> Double {
            var current = item.projectedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ShiftMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultShiftMappingEngine() -> ShiftMappingEngine {
        return ShiftMappingEngine(
            steps: [
                ShiftMappingSequenceOffsetAdjuster(weight: 0.55),
                PercentShiftMappingAdjuster(percent: 9.4),
                MinimumShiftMappingAdjuster(minimum: 17.4),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 58265.1
        )
    }
}
