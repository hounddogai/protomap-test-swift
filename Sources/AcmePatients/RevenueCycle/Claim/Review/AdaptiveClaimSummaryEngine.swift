import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive claim summary calculation.
    protocol AdaptiveClaimSummaryModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveClaimSummary, value: Double) -> Double
    }

    final class PercentAdaptiveClaimSummaryAdjuster: AdaptiveClaimSummaryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveClaimSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAdaptiveClaimSummaryAdjuster: AdaptiveClaimSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveClaimSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveClaimSummaryAdjuster: AdaptiveClaimSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveClaimSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive claim summary steps in order and keeps a trace of each.
    final class AdaptiveClaimSummaryEngine {
        var steps: [any AdaptiveClaimSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveClaimSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveClaimSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveClaimSummaryModifier = steps[index]
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

        func evaluateAll(_ items: [AdaptiveClaimSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveClaimSummaryEngine() -> AdaptiveClaimSummaryEngine {
        return AdaptiveClaimSummaryEngine(
            steps: [
                PercentAdaptiveClaimSummaryAdjuster(percent: -10.7),
                TieredAdaptiveClaimSummaryAdjuster(bounds: [4535.0, 6625.0], rates: [1.02, 1.04]),
                RoundingAdaptiveClaimSummaryAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 76890.4
        )
    }
}
