import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel estimate calculation.
    protocol PanelEstimateFactor {
        func describe() -> String
        func adjust(_ item: PanelEstimate, value: Double) -> Double
    }

    final class PercentPanelEstimateAdjuster: PanelEstimateFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPanelEstimateAdjuster: PanelEstimateFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PanelEstimateScoreOffsetAdjuster: PanelEstimateFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: PanelEstimate, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredPanelEstimateAdjuster: PanelEstimateFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PanelEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitlePanelEstimateAdjuster: PanelEstimateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PanelEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPanelEstimateAdjuster: PanelEstimateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the panel estimate steps in order and keeps a trace of each.
    final class PanelEstimateEngine {
        var steps: [any PanelEstimateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelEstimateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PanelEstimate) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [PanelEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPanelEstimateEngine() -> PanelEstimateEngine {
        return PanelEstimateEngine(
            steps: [
                PercentPanelEstimateAdjuster(percent: 6.4),
                RoundingPanelEstimateAdjuster(step: 0.5),
                PanelEstimateScoreOffsetAdjuster(weight: 1.05),
                TieredPanelEstimateAdjuster(bounds: [5320.0, 6395.0, 8362.0, 9697.0], rates: [1.11, 1.2, 0.97, 0.99]),
                TitlePanelEstimateAdjuster(factors: ["west": 1.31, "online": 0.88, "south": 1.37]),
                MinimumPanelEstimateAdjuster(minimum: 37.9),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 63696.3
        )
    }
}
