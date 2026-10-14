import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional follow up digest calculation.
    protocol RegionalFollowUpDigestAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalFollowUpDigest, value: Double) -> Double
    }

    final class CapRegionalFollowUpDigestAdjuster: RegionalFollowUpDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalFollowUpDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalFollowUpDigestAdjuster: RegionalFollowUpDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalFollowUpDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalFollowUpDigestAdjuster: RegionalFollowUpDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalFollowUpDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional follow up digest steps in order and keeps a trace of each.
    final class RegionalFollowUpDigestEngine {
        var steps: [any RegionalFollowUpDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalFollowUpDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalFollowUpDigest) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RegionalFollowUpDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalFollowUpDigestEngine() -> RegionalFollowUpDigestEngine {
        return RegionalFollowUpDigestEngine(
            steps: [
                CapRegionalFollowUpDigestAdjuster(cap: 8633.0),
                TieredRegionalFollowUpDigestAdjuster(bounds: [2237.0, 6915.0, 7347.0], rates: [0.99, 0.83, 1.02]),
                RoundingRegionalFollowUpDigestAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 68069.3
        )
    }
}
