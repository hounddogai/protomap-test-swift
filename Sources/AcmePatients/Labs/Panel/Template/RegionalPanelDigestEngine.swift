import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional panel digest calculation.
    protocol RegionalPanelDigestModifier {
        func describe() -> String
        func adjust(_ item: RegionalPanelDigest, value: Double) -> Double
    }

    final class CapRegionalPanelDigestAdjuster: RegionalPanelDigestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalPanelDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRegionalPanelDigestAdjuster: RegionalPanelDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalPanelDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRegionalPanelDigestAdjuster: RegionalPanelDigestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalPanelDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitRegionalPanelDigestAdjuster: RegionalPanelDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: RegionalPanelDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRegionalPanelDigestAdjuster: RegionalPanelDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalPanelDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional panel digest steps in order and keeps a trace of each.
    final class RegionalPanelDigestEngine {
        var steps: [any RegionalPanelDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalPanelDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalPanelDigest) -> Double {
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

        func evaluateAll(_ items: [RegionalPanelDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalPanelDigestEngine() -> RegionalPanelDigestEngine {
        return RegionalPanelDigestEngine(
            steps: [
                CapRegionalPanelDigestAdjuster(cap: 21105.0),
                TieredRegionalPanelDigestAdjuster(bounds: [2086.0, 5112.0, 7870.0], rates: [1.2, 0.82, 1.03]),
                RoundingRegionalPanelDigestAdjuster(step: 0.25),
                UnitRegionalPanelDigestAdjuster(factors: ["retail": 1.26, "central": 1.27, "north": 1.17]),
                PercentRegionalPanelDigestAdjuster(percent: 14.9),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 12713.5
        )
    }
}
