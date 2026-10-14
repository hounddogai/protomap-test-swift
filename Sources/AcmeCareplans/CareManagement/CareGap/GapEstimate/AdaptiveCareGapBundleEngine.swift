import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive care gap bundle calculation.
    protocol AdaptiveCareGapBundleStep {
        func describe() -> String
        func adjust(_ item: AdaptiveCareGapBundle, value: Double) -> Double
    }

    final class MinimumAdaptiveCareGapBundleAdjuster: AdaptiveCareGapBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveCareGapBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAdaptiveCareGapBundleAdjuster: AdaptiveCareGapBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveCareGapBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CategoryAdaptiveCareGapBundleAdjuster: AdaptiveCareGapBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: AdaptiveCareGapBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAdaptiveCareGapBundleAdjuster: AdaptiveCareGapBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveCareGapBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive care gap bundle steps in order and keeps a trace of each.
    final class AdaptiveCareGapBundleEngine {
        var steps: [any AdaptiveCareGapBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveCareGapBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveCareGapBundle) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveCareGapBundleStep = steps[index]
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

        func evaluateAll(_ items: [AdaptiveCareGapBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveCareGapBundleEngine() -> AdaptiveCareGapBundleEngine {
        return AdaptiveCareGapBundleEngine(
            steps: [
                MinimumAdaptiveCareGapBundleAdjuster(minimum: 49.1),
                TieredAdaptiveCareGapBundleAdjuster(
                    bounds: [499.0, 2457.0, 3805.0, 9164.0],
                    rates: [0.94, 1.04, 0.87, 0.84]
                ),
                CategoryAdaptiveCareGapBundleAdjuster(factors: ["central": 0.75]),
                PercentAdaptiveCareGapBundleAdjuster(percent: -15.8),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 65222.7
        )
    }
}
