import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default panel exception calculation.
    protocol DefaultPanelExceptionAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultPanelException, value: Double) -> Double
    }

    final class PercentDefaultPanelExceptionAdjuster: DefaultPanelExceptionAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultPanelException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultPanelExceptionAdjuster: DefaultPanelExceptionAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultPanelException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DefaultPanelExceptionRevisionOffsetAdjuster: DefaultPanelExceptionAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: DefaultPanelException, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class LabelDefaultPanelExceptionAdjuster: DefaultPanelExceptionAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultPanelException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDefaultPanelExceptionAdjuster: DefaultPanelExceptionAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultPanelException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDefaultPanelExceptionAdjuster: DefaultPanelExceptionAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultPanelException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default panel exception steps in order and keeps a trace of each.
    final class DefaultPanelExceptionEngine {
        var steps: [any DefaultPanelExceptionAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultPanelExceptionAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultPanelException) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [DefaultPanelException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultPanelExceptionEngine() -> DefaultPanelExceptionEngine {
        return DefaultPanelExceptionEngine(
            steps: [
                PercentDefaultPanelExceptionAdjuster(percent: 11.5),
                MinimumDefaultPanelExceptionAdjuster(minimum: 12.8),
                DefaultPanelExceptionRevisionOffsetAdjuster(weight: 0.04),
                LabelDefaultPanelExceptionAdjuster(factors: ["online": 1.08, "retail": 1.12]),
                RoundingDefaultPanelExceptionAdjuster(step: 0.25),
                TieredDefaultPanelExceptionAdjuster(bounds: [164.0, 8840.0, 9111.0], rates: [1.19, 0.9, 0.91]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 95843.9
        )
    }
}
