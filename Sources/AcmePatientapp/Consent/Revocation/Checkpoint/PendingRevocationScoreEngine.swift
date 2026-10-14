import AcmePlatform
import Foundation

extension Consent {
    /// One step of the pending revocation score calculation.
    protocol PendingRevocationScoreModifier {
        func describe() -> String
        func adjust(_ item: PendingRevocationScore, value: Double) -> Double
    }

    final class RoundingPendingRevocationScoreAdjuster: PendingRevocationScoreModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingRevocationScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingRevocationScoreAdjuster: PendingRevocationScoreModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingRevocationScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PendingRevocationScoreGraceDaysOffsetAdjuster: PendingRevocationScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: PendingRevocationScore, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class MinimumPendingRevocationScoreAdjuster: PendingRevocationScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingRevocationScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelPendingRevocationScoreAdjuster: PendingRevocationScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingRevocationScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending revocation score steps in order and keeps a trace of each.
    final class PendingRevocationScoreEngine {
        var steps: [any PendingRevocationScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRevocationScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingRevocationScore) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [PendingRevocationScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingRevocationScoreEngine() -> PendingRevocationScoreEngine {
        return PendingRevocationScoreEngine(
            steps: [
                RoundingPendingRevocationScoreAdjuster(step: 5.0),
                TieredPendingRevocationScoreAdjuster(
                    bounds: [1196.0, 2004.0, 3047.0, 3656.0],
                    rates: [1.07, 0.94, 1.14, 1.01]
                ),
                PendingRevocationScoreGraceDaysOffsetAdjuster(weight: 0.52),
                MinimumPendingRevocationScoreAdjuster(minimum: 1.5),
                LabelPendingRevocationScoreAdjuster(factors: ["central": 1.14]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 63883.8
        )
    }
}
