import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy eligibility baseline calculation.
    protocol LegacyEligibilityBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyEligibilityBaseline, value: Double) -> Double
    }

    final class CapLegacyEligibilityBaselineAdjuster: LegacyEligibilityBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyEligibilityBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyEligibilityBaselineCeilingOffsetAdjuster: LegacyEligibilityBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: LegacyEligibilityBaseline, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class TieredLegacyEligibilityBaselineAdjuster: LegacyEligibilityBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyEligibilityBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy eligibility baseline steps in order and keeps a trace of each.
    final class LegacyEligibilityBaselineEngine {
        var steps: [any LegacyEligibilityBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyEligibilityBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyEligibilityBaseline) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [LegacyEligibilityBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyEligibilityBaselineEngine() -> LegacyEligibilityBaselineEngine {
        return LegacyEligibilityBaselineEngine(
            steps: [
                CapLegacyEligibilityBaselineAdjuster(cap: 48258.0),
                LegacyEligibilityBaselineCeilingOffsetAdjuster(weight: 0.15),
                TieredLegacyEligibilityBaselineAdjuster(bounds: [3068.0, 3379.0], rates: [0.89, 1.14]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 14007.6
        )
    }
}
