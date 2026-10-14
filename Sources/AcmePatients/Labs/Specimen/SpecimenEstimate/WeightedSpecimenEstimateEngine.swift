import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted specimen estimate calculation.
    protocol WeightedSpecimenEstimateStep {
        func describe() -> String
        func adjust(_ item: WeightedSpecimenEstimate, value: Double) -> Double
    }

    final class MinimumWeightedSpecimenEstimateAdjuster: WeightedSpecimenEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedSpecimenEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWeightedSpecimenEstimateAdjuster: WeightedSpecimenEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSpecimenEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedSpecimenEstimateRatioOffsetAdjuster: WeightedSpecimenEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: WeightedSpecimenEstimate, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class SourceWeightedSpecimenEstimateAdjuster: WeightedSpecimenEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: WeightedSpecimenEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the weighted specimen estimate steps in order and keeps a trace of each.
    final class WeightedSpecimenEstimateEngine {
        var steps: [any WeightedSpecimenEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSpecimenEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedSpecimenEstimate) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSpecimenEstimateStep = steps[index]
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

        func evaluateAll(_ items: [WeightedSpecimenEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedSpecimenEstimateEngine() -> WeightedSpecimenEstimateEngine {
        return WeightedSpecimenEstimateEngine(
            steps: [
                MinimumWeightedSpecimenEstimateAdjuster(minimum: 39.4),
                CapWeightedSpecimenEstimateAdjuster(cap: 40653.0),
                WeightedSpecimenEstimateRatioOffsetAdjuster(weight: 0.53),
                SourceWeightedSpecimenEstimateAdjuster(factors: ["north": 1.18, "central": 0.82, "east": 1.2]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 76425.4
        )
    }
}
