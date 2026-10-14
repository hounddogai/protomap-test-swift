import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility snapshot calculation.
    protocol EligibilitySnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: EligibilitySnapshot, value: Double) -> Double
    }

    final class CapEligibilitySnapshotAdjuster: EligibilitySnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilitySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredEligibilitySnapshotAdjuster: EligibilitySnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilitySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class EligibilitySnapshotQuantityOffsetAdjuster: EligibilitySnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: EligibilitySnapshot, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumEligibilitySnapshotAdjuster: EligibilitySnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilitySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelEligibilitySnapshotAdjuster: EligibilitySnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: EligibilitySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentEligibilitySnapshotAdjuster: EligibilitySnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilitySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility snapshot steps in order and keeps a trace of each.
    final class EligibilitySnapshotEngine {
        var steps: [any EligibilitySnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilitySnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilitySnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [EligibilitySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilitySnapshotEngine() -> EligibilitySnapshotEngine {
        return EligibilitySnapshotEngine(
            steps: [
                CapEligibilitySnapshotAdjuster(cap: 20620.0),
                TieredEligibilitySnapshotAdjuster(
                    bounds: [539.0, 4398.0, 5469.0, 7487.0],
                    rates: [0.87, 1.14, 0.95, 1.05]
                ),
                EligibilitySnapshotQuantityOffsetAdjuster(weight: 1.14),
                MinimumEligibilitySnapshotAdjuster(minimum: 19.3),
                LabelEligibilitySnapshotAdjuster(factors: ["north": 0.79]),
                PercentEligibilitySnapshotAdjuster(percent: -21.8),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 52885.6
        )
    }
}
