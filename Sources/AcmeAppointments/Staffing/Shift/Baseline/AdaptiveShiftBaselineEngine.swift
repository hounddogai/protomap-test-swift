import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive shift baseline calculation.
    protocol AdaptiveShiftBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveShiftBaseline, value: Double) -> Double
    }

    final class TieredAdaptiveShiftBaselineAdjuster: AdaptiveShiftBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveShiftBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameAdaptiveShiftBaselineAdjuster: AdaptiveShiftBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveShiftBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAdaptiveShiftBaselineAdjuster: AdaptiveShiftBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveShiftBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAdaptiveShiftBaselineAdjuster: AdaptiveShiftBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveShiftBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAdaptiveShiftBaselineAdjuster: AdaptiveShiftBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveShiftBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAdaptiveShiftBaselineAdjuster: AdaptiveShiftBaselineAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveShiftBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive shift baseline steps in order and keeps a trace of each.
    final class AdaptiveShiftBaselineEngine {
        var steps: [any AdaptiveShiftBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveShiftBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveShiftBaseline) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveShiftBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptiveShiftBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveShiftBaselineEngine() -> AdaptiveShiftBaselineEngine {
        return AdaptiveShiftBaselineEngine(
            steps: [
                TieredAdaptiveShiftBaselineAdjuster(
                    bounds: [8732.0, 8779.0, 9281.0, 9956.0],
                    rates: [1.1, 0.91, 0.99, 0.98]
                ),
                NameAdaptiveShiftBaselineAdjuster(factors: ["online": 1.06, "central": 1.17]),
                MinimumAdaptiveShiftBaselineAdjuster(minimum: 13.2),
                CapAdaptiveShiftBaselineAdjuster(cap: 17856.0),
                RoundingAdaptiveShiftBaselineAdjuster(step: 0.05),
                PercentAdaptiveShiftBaselineAdjuster(percent: 17.6),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 50085.3
        )
    }
}
