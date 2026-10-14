import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default risk score threshold calculation.
    protocol DefaultRiskScoreThresholdStep {
        func describe() -> String
        func adjust(_ item: DefaultRiskScoreThreshold, value: Double) -> Double
    }

    final class PercentDefaultRiskScoreThresholdAdjuster: DefaultRiskScoreThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRiskScoreThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleDefaultRiskScoreThresholdAdjuster: DefaultRiskScoreThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DefaultRiskScoreThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDefaultRiskScoreThresholdAdjuster: DefaultRiskScoreThresholdStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultRiskScoreThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DefaultRiskScoreThresholdCeilingOffsetAdjuster: DefaultRiskScoreThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: DefaultRiskScoreThreshold, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the default risk score threshold steps in order and keeps a trace of each.
    final class DefaultRiskScoreThresholdEngine {
        var steps: [any DefaultRiskScoreThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRiskScoreThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultRiskScoreThreshold) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRiskScoreThresholdStep = steps[index]
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

        func evaluateAll(_ items: [DefaultRiskScoreThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultRiskScoreThresholdEngine() -> DefaultRiskScoreThresholdEngine {
        return DefaultRiskScoreThresholdEngine(
            steps: [
                PercentDefaultRiskScoreThresholdAdjuster(percent: 9.7),
                TitleDefaultRiskScoreThresholdAdjuster(factors: ["central": 0.77]),
                TieredDefaultRiskScoreThresholdAdjuster(bounds: [1663.0, 7533.0], rates: [1.14, 1.06]),
                DefaultRiskScoreThresholdCeilingOffsetAdjuster(weight: 1.63),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 24771.9
        )
    }
}
