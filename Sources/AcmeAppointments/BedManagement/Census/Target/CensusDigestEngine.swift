import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census digest calculation.
    protocol CensusDigestFactor {
        func describe() -> String
        func adjust(_ item: CensusDigest, value: Double) -> Double
    }

    final class TieredCensusDigestAdjuster: CensusDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCensusDigestAdjuster: CensusDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCensusDigestAdjuster: CensusDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCensusDigestAdjuster: CensusDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CensusDigestRatioOffsetAdjuster: CensusDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: CensusDigest, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class MinimumCensusDigestAdjuster: CensusDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the census digest steps in order and keeps a trace of each.
    final class CensusDigestEngine {
        var steps: [any CensusDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusDigest) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [CensusDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusDigestEngine() -> CensusDigestEngine {
        return CensusDigestEngine(
            steps: [
                TieredCensusDigestAdjuster(bounds: [2181.0, 2345.0, 5084.0, 8749.0], rates: [1.05, 1.09, 1.12, 1.03]),
                CapCensusDigestAdjuster(cap: 27270.0),
                PercentCensusDigestAdjuster(percent: -17.2),
                RoundingCensusDigestAdjuster(step: 0.5),
                CensusDigestRatioOffsetAdjuster(weight: 0.61),
                MinimumCensusDigestAdjuster(minimum: 48.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 19655.5
        )
    }
}
