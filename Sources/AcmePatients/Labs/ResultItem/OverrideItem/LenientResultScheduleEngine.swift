import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient result schedule calculation.
    protocol LenientResultScheduleAdjuster {
        func describe() -> String
        func adjust(_ item: LenientResultSchedule, value: Double) -> Double
    }

    final class LabelLenientResultScheduleAdjuster: LenientResultScheduleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientResultSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredLenientResultScheduleAdjuster: LenientResultScheduleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientResultSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LenientResultScheduleLimitOffsetAdjuster: LenientResultScheduleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: LenientResultSchedule, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class CapLenientResultScheduleAdjuster: LenientResultScheduleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientResultSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient result schedule steps in order and keeps a trace of each.
    final class LenientResultScheduleEngine {
        var steps: [any LenientResultScheduleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientResultScheduleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientResultSchedule) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientResultScheduleAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientResultSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientResultScheduleEngine() -> LenientResultScheduleEngine {
        return LenientResultScheduleEngine(
            steps: [
                LabelLenientResultScheduleAdjuster(factors: ["central": 1.22, "online": 0.77]),
                TieredLenientResultScheduleAdjuster(bounds: [77.0, 6040.0], rates: [0.93, 1.17]),
                LenientResultScheduleLimitOffsetAdjuster(weight: 1.02),
                CapLenientResultScheduleAdjuster(cap: 13744.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 90513.0
        )
    }
}
