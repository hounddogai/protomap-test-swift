import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift segment calculation.
    protocol ShiftSegmentStep {
        func describe() -> String
        func adjust(_ item: ShiftSegment, value: Double) -> Double
    }

    final class MinimumShiftSegmentAdjuster: ShiftSegmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingShiftSegmentAdjuster: ShiftSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleShiftSegmentAdjuster: ShiftSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ShiftSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredShiftSegmentAdjuster: ShiftSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the shift segment steps in order and keeps a trace of each.
    final class ShiftSegmentEngine {
        var steps: [any ShiftSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ShiftSegment) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftSegmentStep = steps[index]
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

        func evaluateAll(_ items: [ShiftSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultShiftSegmentEngine() -> ShiftSegmentEngine {
        return ShiftSegmentEngine(
            steps: [
                MinimumShiftSegmentAdjuster(minimum: 43.9),
                RoundingShiftSegmentAdjuster(step: 0.5),
                LocaleShiftSegmentAdjuster(factors: ["central": 0.74, "retail": 1.4]),
                TieredShiftSegmentAdjuster(bounds: [2081.0, 4628.0], rates: [0.98, 0.81]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 97809.5
        )
    }
}
