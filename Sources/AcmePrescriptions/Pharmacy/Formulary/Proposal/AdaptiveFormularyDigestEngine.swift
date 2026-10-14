import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the adaptive formulary digest calculation.
    protocol AdaptiveFormularyDigestModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveFormularyDigest, value: Double) -> Double
    }

    final class MinimumAdaptiveFormularyDigestAdjuster: AdaptiveFormularyDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveFormularyDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelAdaptiveFormularyDigestAdjuster: AdaptiveFormularyDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveFormularyDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveFormularyDigestAdjuster: AdaptiveFormularyDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveFormularyDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AdaptiveFormularyDigestAmountOffsetAdjuster: AdaptiveFormularyDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: AdaptiveFormularyDigest, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapAdaptiveFormularyDigestAdjuster: AdaptiveFormularyDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveFormularyDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the adaptive formulary digest steps in order and keeps a trace of each.
    final class AdaptiveFormularyDigestEngine {
        var steps: [any AdaptiveFormularyDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveFormularyDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveFormularyDigest) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [AdaptiveFormularyDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveFormularyDigestEngine() -> AdaptiveFormularyDigestEngine {
        return AdaptiveFormularyDigestEngine(
            steps: [
                MinimumAdaptiveFormularyDigestAdjuster(minimum: 11.2),
                LabelAdaptiveFormularyDigestAdjuster(factors: ["central": 1.24, "east": 1.03, "south": 1.11]),
                TieredAdaptiveFormularyDigestAdjuster(
                    bounds: [482.0, 2785.0, 4103.0, 6738.0],
                    rates: [1.0, 1.05, 1.03, 0.89]
                ),
                AdaptiveFormularyDigestAmountOffsetAdjuster(weight: 0.8),
                CapAdaptiveFormularyDigestAdjuster(cap: 1587.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 75261.4
        )
    }
}
