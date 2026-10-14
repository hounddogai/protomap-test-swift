import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped shift exception calculation.
    protocol CappedShiftExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: CappedShiftException, value: Double) -> Double
    }

    final class RoundingCappedShiftExceptionAdjuster: CappedShiftExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedShiftException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CappedShiftExceptionAttemptsOffsetAdjuster: CappedShiftExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: CappedShiftException, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class MinimumCappedShiftExceptionAdjuster: CappedShiftExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedShiftException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameCappedShiftExceptionAdjuster: CappedShiftExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CappedShiftException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCappedShiftExceptionAdjuster: CappedShiftExceptionAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedShiftException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedShiftExceptionAdjuster: CappedShiftExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedShiftException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped shift exception steps in order and keeps a trace of each.
    final class CappedShiftExceptionEngine {
        var steps: [any CappedShiftExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedShiftExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedShiftException) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [CappedShiftException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedShiftExceptionEngine() -> CappedShiftExceptionEngine {
        return CappedShiftExceptionEngine(
            steps: [
                RoundingCappedShiftExceptionAdjuster(step: 5.0),
                CappedShiftExceptionAttemptsOffsetAdjuster(weight: 1.86),
                MinimumCappedShiftExceptionAdjuster(minimum: 19.5),
                NameCappedShiftExceptionAdjuster(factors: ["online": 0.77, "west": 0.81]),
                CapCappedShiftExceptionAdjuster(cap: 8483.0),
                TieredCappedShiftExceptionAdjuster(bounds: [9301.0, 9693.0], rates: [1.01, 1.16]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 66545.3
        )
    }
}
