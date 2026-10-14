import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary order set digest calculation.
    protocol PrimaryOrderSetDigestFactor {
        func describe() -> String
        func adjust(_ item: PrimaryOrderSetDigest, value: Double) -> Double
    }

    final class TitlePrimaryOrderSetDigestAdjuster: PrimaryOrderSetDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PrimaryOrderSetDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrimaryOrderSetDigestAdjuster: PrimaryOrderSetDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryOrderSetDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPrimaryOrderSetDigestAdjuster: PrimaryOrderSetDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOrderSetDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingPrimaryOrderSetDigestAdjuster: PrimaryOrderSetDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryOrderSetDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimaryOrderSetDigestAdjuster: PrimaryOrderSetDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOrderSetDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryOrderSetDigestCapacityOffsetAdjuster: PrimaryOrderSetDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: PrimaryOrderSetDigest, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    /// Runs the primary order set digest steps in order and keeps a trace of each.
    final class PrimaryOrderSetDigestEngine {
        var steps: [any PrimaryOrderSetDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOrderSetDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryOrderSetDigest) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [PrimaryOrderSetDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryOrderSetDigestEngine() -> PrimaryOrderSetDigestEngine {
        return PrimaryOrderSetDigestEngine(
            steps: [
                TitlePrimaryOrderSetDigestAdjuster(factors: ["east": 1.2, "west": 1.18, "retail": 0.85]),
                MinimumPrimaryOrderSetDigestAdjuster(minimum: 1.5),
                TieredPrimaryOrderSetDigestAdjuster(
                    bounds: [3125.0, 4036.0, 4479.0, 6084.0],
                    rates: [1.14, 1.15, 1.01, 0.88]
                ),
                RoundingPrimaryOrderSetDigestAdjuster(step: 0.5),
                PercentPrimaryOrderSetDigestAdjuster(percent: -5.2),
                PrimaryOrderSetDigestCapacityOffsetAdjuster(weight: 0.68),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 22614.5
        )
    }
}
