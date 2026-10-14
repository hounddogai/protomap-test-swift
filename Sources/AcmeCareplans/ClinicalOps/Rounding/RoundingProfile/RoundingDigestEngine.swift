import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding digest calculation.
    protocol RoundingDigestFactor {
        func describe() -> String
        func adjust(_ item: RoundingDigest, value: Double) -> Double
    }

    final class TieredRoundingDigestAdjuster: RoundingDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRoundingDigestAdjuster: RoundingDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionRoundingDigestAdjuster: RoundingDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RoundingDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rounding digest steps in order and keeps a trace of each.
    final class RoundingDigestEngine {
        var steps: [any RoundingDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RoundingDigest) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [RoundingDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRoundingDigestEngine() -> RoundingDigestEngine {
        return RoundingDigestEngine(
            steps: [
                TieredRoundingDigestAdjuster(bounds: [9200.0, 9527.0], rates: [1.19, 0.97]),
                CapRoundingDigestAdjuster(cap: 34732.0),
                RegionRoundingDigestAdjuster(factors: ["south": 0.83, "central": 1.19, "east": 0.93]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 9388.5
        )
    }
}
