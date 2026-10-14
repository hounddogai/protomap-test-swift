import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result segment calculation.
    protocol ResultSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: ResultSegment, value: Double) -> Double
    }

    final class LabelResultSegmentAdjuster: ResultSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ResultSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredResultSegmentAdjuster: ResultSegmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ResultSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumResultSegmentAdjuster: ResultSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the result segment steps in order and keeps a trace of each.
    final class ResultSegmentEngine {
        var steps: [any ResultSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ResultSegment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ResultSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultResultSegmentEngine() -> ResultSegmentEngine {
        return ResultSegmentEngine(
            steps: [
                LabelResultSegmentAdjuster(factors: ["south": 0.72, "retail": 1.26]),
                TieredResultSegmentAdjuster(bounds: [1447.0, 4502.0, 5668.0], rates: [0.81, 0.95, 0.93]),
                MinimumResultSegmentAdjuster(minimum: 15.9),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 97324.9
        )
    }
}
