import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback interaction digest calculation.
    protocol FallbackInteractionDigestStep {
        func describe() -> String
        func adjust(_ item: FallbackInteractionDigest, value: Double) -> Double
    }

    final class PercentFallbackInteractionDigestAdjuster: FallbackInteractionDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackInteractionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackInteractionDigestAdjuster: FallbackInteractionDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackInteractionDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitFallbackInteractionDigestAdjuster: FallbackInteractionDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: FallbackInteractionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback interaction digest steps in order and keeps a trace of each.
    final class FallbackInteractionDigestEngine {
        var steps: [any FallbackInteractionDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackInteractionDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackInteractionDigest) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackInteractionDigestStep = steps[index]
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

        func evaluateAll(_ items: [FallbackInteractionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackInteractionDigestEngine() -> FallbackInteractionDigestEngine {
        return FallbackInteractionDigestEngine(
            steps: [
                PercentFallbackInteractionDigestAdjuster(percent: 16.1),
                TieredFallbackInteractionDigestAdjuster(
                    bounds: [2524.0, 3501.0, 7388.0, 8434.0],
                    rates: [0.99, 1.0, 1.1, 1.0]
                ),
                UnitFallbackInteractionDigestAdjuster(factors: ["south": 1.06]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 1801.2
        )
    }
}
