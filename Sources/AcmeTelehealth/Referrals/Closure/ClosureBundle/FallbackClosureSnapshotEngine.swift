import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback closure snapshot calculation.
    protocol FallbackClosureSnapshotModifier {
        func describe() -> String
        func adjust(_ item: FallbackClosureSnapshot, value: Double) -> Double
    }

    final class FallbackClosureSnapshotDiscountOffsetAdjuster: FallbackClosureSnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FallbackClosureSnapshot, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CapFallbackClosureSnapshotAdjuster: FallbackClosureSnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackClosureSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFallbackClosureSnapshotAdjuster: FallbackClosureSnapshotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackClosureSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback closure snapshot steps in order and keeps a trace of each.
    final class FallbackClosureSnapshotEngine {
        var steps: [any FallbackClosureSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackClosureSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackClosureSnapshot) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackClosureSnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [FallbackClosureSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackClosureSnapshotEngine() -> FallbackClosureSnapshotEngine {
        return FallbackClosureSnapshotEngine(
            steps: [
                FallbackClosureSnapshotDiscountOffsetAdjuster(weight: 1.37),
                CapFallbackClosureSnapshotAdjuster(cap: 35285.0),
                TieredFallbackClosureSnapshotAdjuster(
                    bounds: [1599.0, 4998.0, 7849.0, 9438.0],
                    rates: [0.82, 1.14, 0.88, 0.99]
                ),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 77306.4
        )
    }
}
