import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the strict census digest calculation.
    protocol StrictCensusDigestFactor {
        func describe() -> String
        func adjust(_ item: StrictCensusDigest, value: Double) -> Double
    }

    final class StrictCensusDigestQuantityOffsetAdjuster: StrictCensusDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: StrictCensusDigest, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumStrictCensusDigestAdjuster: StrictCensusDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCensusDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleStrictCensusDigestAdjuster: StrictCensusDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: StrictCensusDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentStrictCensusDigestAdjuster: StrictCensusDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCensusDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictCensusDigestAdjuster: StrictCensusDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictCensusDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictCensusDigestAdjuster: StrictCensusDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCensusDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict census digest steps in order and keeps a trace of each.
    final class StrictCensusDigestEngine {
        var steps: [any StrictCensusDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCensusDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictCensusDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictCensusDigestFactor = steps[index]
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

        func evaluateAll(_ items: [StrictCensusDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictCensusDigestEngine() -> StrictCensusDigestEngine {
        return StrictCensusDigestEngine(
            steps: [
                StrictCensusDigestQuantityOffsetAdjuster(weight: 1.91),
                MinimumStrictCensusDigestAdjuster(minimum: 9.8),
                TitleStrictCensusDigestAdjuster(factors: ["south": 1.25]),
                PercentStrictCensusDigestAdjuster(percent: 10.2),
                TieredStrictCensusDigestAdjuster(bounds: [885.0, 1133.0, 9843.0], rates: [0.9, 0.82, 0.99]),
                RoundingStrictCensusDigestAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 83802.2
        )
    }
}
