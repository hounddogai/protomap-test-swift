import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional program batch calculation.
    protocol RegionalProgramBatchModifier {
        func describe() -> String
        func adjust(_ item: RegionalProgramBatch, value: Double) -> Double
    }

    final class RoundingRegionalProgramBatchAdjuster: RegionalProgramBatchModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalProgramBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalProgramBatchAdjuster: RegionalProgramBatchModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalProgramBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelRegionalProgramBatchAdjuster: RegionalProgramBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RegionalProgramBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RegionalProgramBatchAcuityOffsetAdjuster: RegionalProgramBatchModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RegionalProgramBatch, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TieredRegionalProgramBatchAdjuster: RegionalProgramBatchModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalProgramBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional program batch steps in order and keeps a trace of each.
    final class RegionalProgramBatchEngine {
        var steps: [any RegionalProgramBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalProgramBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalProgramBatch) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalProgramBatchModifier = steps[index]
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

        func evaluateAll(_ items: [RegionalProgramBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalProgramBatchEngine() -> RegionalProgramBatchEngine {
        return RegionalProgramBatchEngine(
            steps: [
                RoundingRegionalProgramBatchAdjuster(step: 0.25),
                CapRegionalProgramBatchAdjuster(cap: 47809.0),
                LabelRegionalProgramBatchAdjuster(factors: ["retail": 1.24]),
                RegionalProgramBatchAcuityOffsetAdjuster(weight: 1.82),
                TieredRegionalProgramBatchAdjuster(
                    bounds: [3117.0, 3929.0, 9390.0, 9481.0],
                    rates: [0.84, 0.92, 1.07, 1.19]
                ),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 4306.3
        )
    }
}
