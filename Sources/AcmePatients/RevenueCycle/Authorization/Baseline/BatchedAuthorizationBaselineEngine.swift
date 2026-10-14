import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched authorization baseline calculation.
    protocol BatchedAuthorizationBaselineModifier {
        func describe() -> String
        func adjust(_ item: BatchedAuthorizationBaseline, value: Double) -> Double
    }

    final class CapBatchedAuthorizationBaselineAdjuster: BatchedAuthorizationBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedAuthorizationBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedAuthorizationBaselineAdjuster: BatchedAuthorizationBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedAuthorizationBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedAuthorizationBaselineAdjuster: BatchedAuthorizationBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedAuthorizationBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched authorization baseline steps in order and keeps a trace of each.
    final class BatchedAuthorizationBaselineEngine {
        var steps: [any BatchedAuthorizationBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAuthorizationBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedAuthorizationBaseline) -> Double {
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

        func evaluateAll(_ items: [BatchedAuthorizationBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedAuthorizationBaselineEngine() -> BatchedAuthorizationBaselineEngine {
        return BatchedAuthorizationBaselineEngine(
            steps: [
                CapBatchedAuthorizationBaselineAdjuster(cap: 26071.0),
                TieredBatchedAuthorizationBaselineAdjuster(bounds: [3795.0, 6252.0], rates: [0.85, 1.17]),
                PercentBatchedAuthorizationBaselineAdjuster(percent: -13.1),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 20893.2
        )
    }
}
