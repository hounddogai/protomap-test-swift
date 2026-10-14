import AcmePlatform
import Foundation

extension Labs {
    /// One step of the adaptive panel digest calculation.
    protocol AdaptivePanelDigestAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptivePanelDigest, value: Double) -> Double
    }

    final class TieredAdaptivePanelDigestAdjuster: AdaptivePanelDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptivePanelDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptivePanelDigestAdjuster: AdaptivePanelDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptivePanelDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumAdaptivePanelDigestAdjuster: AdaptivePanelDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptivePanelDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAdaptivePanelDigestAdjuster: AdaptivePanelDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptivePanelDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAdaptivePanelDigestAdjuster: AdaptivePanelDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptivePanelDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive panel digest steps in order and keeps a trace of each.
    final class AdaptivePanelDigestEngine {
        var steps: [any AdaptivePanelDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptivePanelDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptivePanelDigest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptivePanelDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [AdaptivePanelDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptivePanelDigestEngine() -> AdaptivePanelDigestEngine {
        return AdaptivePanelDigestEngine(
            steps: [
                TieredAdaptivePanelDigestAdjuster(
                    bounds: [2805.0, 3516.0, 4040.0, 7146.0],
                    rates: [0.86, 0.91, 1.03, 1.1]
                ),
                RoundingAdaptivePanelDigestAdjuster(step: 5.0),
                MinimumAdaptivePanelDigestAdjuster(minimum: 38.0),
                PercentAdaptivePanelDigestAdjuster(percent: 6.4),
                CapAdaptivePanelDigestAdjuster(cap: 43533.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 95510.6
        )
    }
}
