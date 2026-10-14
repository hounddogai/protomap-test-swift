import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling overtime score calculation.
    protocol RollingOvertimeScoreStep {
        func describe() -> String
        func adjust(_ item: RollingOvertimeScore, value: Double) -> Double
    }

    final class RoundingRollingOvertimeScoreAdjuster: RollingOvertimeScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingOvertimeScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRollingOvertimeScoreAdjuster: RollingOvertimeScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingOvertimeScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingOvertimeScoreAdjuster: RollingOvertimeScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingOvertimeScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionRollingOvertimeScoreAdjuster: RollingOvertimeScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RollingOvertimeScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingOvertimeScoreAdjuster: RollingOvertimeScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingOvertimeScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling overtime score steps in order and keeps a trace of each.
    final class RollingOvertimeScoreEngine {
        var steps: [any RollingOvertimeScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingOvertimeScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingOvertimeScore) -> Double {
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

        func evaluateAll(_ items: [RollingOvertimeScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingOvertimeScoreEngine() -> RollingOvertimeScoreEngine {
        return RollingOvertimeScoreEngine(
            steps: [
                RoundingRollingOvertimeScoreAdjuster(step: 0.05),
                TieredRollingOvertimeScoreAdjuster(bounds: [31.0, 6955.0, 9222.0], rates: [1.0, 1.02, 1.0]),
                CapRollingOvertimeScoreAdjuster(cap: 28054.0),
                RegionRollingOvertimeScoreAdjuster(factors: ["central": 0.8, "north": 1.29, "east": 1.02]),
                MinimumRollingOvertimeScoreAdjuster(minimum: 27.2),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 22431.8
        )
    }
}
