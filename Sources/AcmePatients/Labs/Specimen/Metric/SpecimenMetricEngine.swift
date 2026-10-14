import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen metric calculation.
    protocol SpecimenMetricModifier {
        func describe() -> String
        func adjust(_ item: SpecimenMetric, value: Double) -> Double
    }

    final class SpecimenMetricRatioOffsetAdjuster: SpecimenMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: SpecimenMetric, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingSpecimenMetricAdjuster: SpecimenMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSpecimenMetricAdjuster: SpecimenMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredSpecimenMetricAdjuster: SpecimenMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SpecimenMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the specimen metric steps in order and keeps a trace of each.
    final class SpecimenMetricEngine {
        var steps: [any SpecimenMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SpecimenMetric) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenMetricModifier = steps[index]
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

        func evaluateAll(_ items: [SpecimenMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSpecimenMetricEngine() -> SpecimenMetricEngine {
        return SpecimenMetricEngine(
            steps: [
                SpecimenMetricRatioOffsetAdjuster(weight: 1.68),
                RoundingSpecimenMetricAdjuster(step: 1.0),
                CapSpecimenMetricAdjuster(cap: 24505.0),
                TieredSpecimenMetricAdjuster(bounds: [6366.0, 9681.0], rates: [1.06, 1.01]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 92572.2
        )
    }
}
