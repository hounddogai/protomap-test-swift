import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped risk score exception calculation.
    protocol CappedRiskScoreExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: CappedRiskScoreException, value: Double) -> Double
    }

    final class PercentCappedRiskScoreExceptionAdjuster: CappedRiskScoreExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedRiskScoreException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelCappedRiskScoreExceptionAdjuster: CappedRiskScoreExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedRiskScoreException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCappedRiskScoreExceptionAdjuster: CappedRiskScoreExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedRiskScoreException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCappedRiskScoreExceptionAdjuster: CappedRiskScoreExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedRiskScoreException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped risk score exception steps in order and keeps a trace of each.
    final class CappedRiskScoreExceptionEngine {
        var steps: [any CappedRiskScoreExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRiskScoreExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedRiskScoreException) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [CappedRiskScoreException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedRiskScoreExceptionEngine() -> CappedRiskScoreExceptionEngine {
        return CappedRiskScoreExceptionEngine(
            steps: [
                PercentCappedRiskScoreExceptionAdjuster(percent: 6.0),
                LabelCappedRiskScoreExceptionAdjuster(factors: ["retail": 1.23]),
                TieredCappedRiskScoreExceptionAdjuster(bounds: [2845.0, 4440.0, 7434.0], rates: [1.05, 0.98, 0.87]),
                MinimumCappedRiskScoreExceptionAdjuster(minimum: 15.6),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 76928.1
        )
    }
}
