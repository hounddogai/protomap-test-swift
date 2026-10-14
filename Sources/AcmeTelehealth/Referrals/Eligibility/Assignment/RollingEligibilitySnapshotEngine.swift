import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling eligibility snapshot calculation.
    protocol RollingEligibilitySnapshotFactor {
        func describe() -> String
        func adjust(_ item: RollingEligibilitySnapshot, value: Double) -> Double
    }

    final class RoundingRollingEligibilitySnapshotAdjuster: RollingEligibilitySnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingEligibilitySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingEligibilitySnapshotAdjuster: RollingEligibilitySnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingEligibilitySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRollingEligibilitySnapshotAdjuster: RollingEligibilitySnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingEligibilitySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceRollingEligibilitySnapshotAdjuster: RollingEligibilitySnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: RollingEligibilitySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling eligibility snapshot steps in order and keeps a trace of each.
    final class RollingEligibilitySnapshotEngine {
        var steps: [any RollingEligibilitySnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingEligibilitySnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingEligibilitySnapshot) -> Double {
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

        func evaluateAll(_ items: [RollingEligibilitySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingEligibilitySnapshotEngine() -> RollingEligibilitySnapshotEngine {
        return RollingEligibilitySnapshotEngine(
            steps: [
                RoundingRollingEligibilitySnapshotAdjuster(step: 5.0),
                CapRollingEligibilitySnapshotAdjuster(cap: 20143.0),
                TieredRollingEligibilitySnapshotAdjuster(bounds: [2425.0, 3898.0], rates: [1.19, 1.14]),
                SourceRollingEligibilitySnapshotAdjuster(factors: ["west": 1.13]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 41161.1
        )
    }
}
