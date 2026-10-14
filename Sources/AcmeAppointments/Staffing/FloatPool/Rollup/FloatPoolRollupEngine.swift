import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool rollup calculation.
    protocol FloatPoolRollupFactor {
        func describe() -> String
        func adjust(_ item: FloatPoolRollup, value: Double) -> Double
    }

    final class FloatPoolRollupQuantityOffsetAdjuster: FloatPoolRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FloatPoolRollup, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumFloatPoolRollupAdjuster: FloatPoolRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FloatPoolRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelFloatPoolRollupAdjuster: FloatPoolRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FloatPoolRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the float pool rollup steps in order and keeps a trace of each.
    final class FloatPoolRollupEngine {
        var steps: [any FloatPoolRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolRollup) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolRollupFactor = steps[index]
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

        func evaluateAll(_ items: [FloatPoolRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolRollupEngine() -> FloatPoolRollupEngine {
        return FloatPoolRollupEngine(
            steps: [
                FloatPoolRollupQuantityOffsetAdjuster(weight: 0.13),
                MinimumFloatPoolRollupAdjuster(minimum: 29.7),
                LabelFloatPoolRollupAdjuster(factors: ["online": 0.77, "central": 0.98, "north": 1.4]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 81232.1
        )
    }
}
