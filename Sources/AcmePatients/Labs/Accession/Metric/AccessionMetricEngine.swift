import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession metric calculation.
    protocol AccessionMetricModifier {
        func describe() -> String
        func adjust(_ item: AccessionMetric, value: Double) -> Double
    }

    final class MinimumAccessionMetricAdjuster: AccessionMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleAccessionMetricAdjuster: AccessionMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AccessionMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAccessionMetricAdjuster: AccessionMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession metric steps in order and keeps a trace of each.
    final class AccessionMetricEngine {
        var steps: [any AccessionMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AccessionMetric) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionMetricModifier = steps[index]
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

        func evaluateAll(_ items: [AccessionMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAccessionMetricEngine() -> AccessionMetricEngine {
        return AccessionMetricEngine(
            steps: [
                MinimumAccessionMetricAdjuster(minimum: 17.5),
                TitleAccessionMetricAdjuster(factors: ["south": 0.75, "retail": 1.23]),
                PercentAccessionMetricAdjuster(percent: 18.8),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 59452.9
        )
    }
}
