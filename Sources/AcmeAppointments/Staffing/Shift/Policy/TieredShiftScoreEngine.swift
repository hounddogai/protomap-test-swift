import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered shift score calculation.
    protocol PolicyTieredShiftScoreAdjuster {
        func describe() -> String
        func adjust(_ item: TieredShiftScore, value: Double) -> Double
    }

    final class CapTieredShiftScoreAdjuster: PolicyTieredShiftScoreAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredShiftScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredTieredShiftScoreAdjuster: PolicyTieredShiftScoreAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredShiftScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameTieredShiftScoreAdjuster: PolicyTieredShiftScoreAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredShiftScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredShiftScoreAdjuster: PolicyTieredShiftScoreAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredShiftScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingTieredShiftScoreAdjuster: PolicyTieredShiftScoreAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredShiftScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered shift score steps in order and keeps a trace of each.
    final class TieredShiftScoreEngine {
        var steps: [any PolicyTieredShiftScoreAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PolicyTieredShiftScoreAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredShiftScore) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PolicyTieredShiftScoreAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredShiftScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredShiftScoreEngine() -> TieredShiftScoreEngine {
        return TieredShiftScoreEngine(
            steps: [
                CapTieredShiftScoreAdjuster(cap: 45114.0),
                TieredTieredShiftScoreAdjuster(bounds: [2080.0, 4247.0, 9389.0], rates: [0.88, 1.01, 1.08]),
                NameTieredShiftScoreAdjuster(factors: ["south": 1.07]),
                MinimumTieredShiftScoreAdjuster(minimum: 47.5),
                RoundingTieredShiftScoreAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 7620.9
        )
    }
}
