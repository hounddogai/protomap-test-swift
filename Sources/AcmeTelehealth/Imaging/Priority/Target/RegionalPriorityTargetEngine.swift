import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional priority target calculation.
    protocol RegionalPriorityTargetAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalPriorityTarget, value: Double) -> Double
    }

    final class TieredRegionalPriorityTargetAdjuster: RegionalPriorityTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalPriorityTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRegionalPriorityTargetAdjuster: RegionalPriorityTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalPriorityTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalPriorityTargetAdjuster: RegionalPriorityTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalPriorityTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional priority target steps in order and keeps a trace of each.
    final class RegionalPriorityTargetEngine {
        var steps: [any RegionalPriorityTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalPriorityTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalPriorityTarget) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [RegionalPriorityTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalPriorityTargetEngine() -> RegionalPriorityTargetEngine {
        return RegionalPriorityTargetEngine(
            steps: [
                TieredRegionalPriorityTargetAdjuster(bounds: [1687.0, 7539.0], rates: [0.98, 0.9]),
                CapRegionalPriorityTargetAdjuster(cap: 26784.0),
                PercentRegionalPriorityTargetAdjuster(percent: -17.4),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 1698.3
        )
    }
}
