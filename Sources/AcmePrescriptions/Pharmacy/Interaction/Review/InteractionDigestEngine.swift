import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction digest calculation.
    protocol InteractionDigestStep {
        func describe() -> String
        func adjust(_ item: InteractionDigest, value: Double) -> Double
    }

    final class LabelInteractionDigestAdjuster: InteractionDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: InteractionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumInteractionDigestAdjuster: InteractionDigestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class InteractionDigestAttemptsOffsetAdjuster: InteractionDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: InteractionDigest, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class PercentInteractionDigestAdjuster: InteractionDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInteractionDigestAdjuster: InteractionDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the interaction digest steps in order and keeps a trace of each.
    final class InteractionDigestEngine {
        var steps: [any InteractionDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InteractionDigest) -> Double {
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

        func evaluateAll(_ items: [InteractionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInteractionDigestEngine() -> InteractionDigestEngine {
        return InteractionDigestEngine(
            steps: [
                LabelInteractionDigestAdjuster(factors: ["south": 0.74, "east": 1.34]),
                MinimumInteractionDigestAdjuster(minimum: 44.4),
                InteractionDigestAttemptsOffsetAdjuster(weight: 1.28),
                PercentInteractionDigestAdjuster(percent: 24.9),
                TieredInteractionDigestAdjuster(
                    bounds: [1758.0, 3494.0, 6084.0, 6657.0],
                    rates: [0.91, 0.84, 1.17, 0.93]
                ),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 31342.9
        )
    }
}
