import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global follow up metric calculation.
    protocol GlobalFollowUpMetricFactor {
        func describe() -> String
        func adjust(_ item: GlobalFollowUpMetric, value: Double) -> Double
    }

    final class TieredGlobalFollowUpMetricAdjuster: GlobalFollowUpMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalFollowUpMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class GlobalFollowUpMetricRatioOffsetAdjuster: GlobalFollowUpMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: GlobalFollowUpMetric, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapGlobalFollowUpMetricAdjuster: GlobalFollowUpMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalFollowUpMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumGlobalFollowUpMetricAdjuster: GlobalFollowUpMetricFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalFollowUpMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentGlobalFollowUpMetricAdjuster: GlobalFollowUpMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalFollowUpMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global follow up metric steps in order and keeps a trace of each.
    final class GlobalFollowUpMetricEngine {
        var steps: [any GlobalFollowUpMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalFollowUpMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalFollowUpMetric) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [GlobalFollowUpMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalFollowUpMetricEngine() -> GlobalFollowUpMetricEngine {
        return GlobalFollowUpMetricEngine(
            steps: [
                TieredGlobalFollowUpMetricAdjuster(
                    bounds: [2145.0, 2309.0, 2335.0, 6299.0],
                    rates: [0.96, 1.05, 0.87, 1.15]
                ),
                GlobalFollowUpMetricRatioOffsetAdjuster(weight: 0.39),
                CapGlobalFollowUpMetricAdjuster(cap: 19996.0),
                MinimumGlobalFollowUpMetricAdjuster(minimum: 33.7),
                PercentGlobalFollowUpMetricAdjuster(percent: -23.4),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 90884.9
        )
    }
}
