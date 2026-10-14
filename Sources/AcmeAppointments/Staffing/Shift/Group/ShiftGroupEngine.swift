import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift group calculation.
    protocol ShiftGroupFactor {
        func describe() -> String
        func adjust(_ item: ShiftGroup, value: Double) -> Double
    }

    final class PercentShiftGroupAdjuster: ShiftGroupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredShiftGroupAdjuster: ShiftGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapShiftGroupAdjuster: ShiftGroupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleShiftGroupAdjuster: ShiftGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ShiftGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingShiftGroupAdjuster: ShiftGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the shift group steps in order and keeps a trace of each.
    final class ShiftGroupEngine {
        var steps: [any ShiftGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ShiftGroup) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [ShiftGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultShiftGroupEngine() -> ShiftGroupEngine {
        return ShiftGroupEngine(
            steps: [
                PercentShiftGroupAdjuster(percent: 16.5),
                TieredShiftGroupAdjuster(bounds: [1468.0, 2977.0, 4360.0], rates: [1.15, 1.06, 1.13]),
                CapShiftGroupAdjuster(cap: 19827.0),
                TitleShiftGroupAdjuster(factors: ["south": 0.97, "retail": 1.22, "east": 1.16]),
                RoundingShiftGroupAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 1410.3
        )
    }
}
