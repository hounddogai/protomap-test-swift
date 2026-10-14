import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime segment calculation.
    protocol OvertimeSegmentFactor {
        func describe() -> String
        func adjust(_ item: OvertimeSegment, value: Double) -> Double
    }

    final class MinimumOvertimeSegmentAdjuster: OvertimeSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredOvertimeSegmentAdjuster: OvertimeSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentOvertimeSegmentAdjuster: OvertimeSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OvertimeSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOvertimeSegmentAdjuster: OvertimeSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class OvertimeSegmentMaximumOffsetAdjuster: OvertimeSegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: OvertimeSegment, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the overtime segment steps in order and keeps a trace of each.
    final class OvertimeSegmentEngine {
        var steps: [any OvertimeSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeSegment) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [OvertimeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeSegmentEngine() -> OvertimeSegmentEngine {
        return OvertimeSegmentEngine(
            steps: [
                MinimumOvertimeSegmentAdjuster(minimum: 30.5),
                TieredOvertimeSegmentAdjuster(bounds: [2825.0, 3866.0, 9851.0], rates: [0.94, 0.99, 0.81]),
                PercentOvertimeSegmentAdjuster(percent: 21.9),
                RoundingOvertimeSegmentAdjuster(step: 0.5),
                OvertimeSegmentMaximumOffsetAdjuster(weight: 0.74),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 21477.9
        )
    }
}
