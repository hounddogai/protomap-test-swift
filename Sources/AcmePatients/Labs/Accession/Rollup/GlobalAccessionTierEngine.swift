import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global accession tier calculation.
    protocol GlobalAccessionTierFactor {
        func describe() -> String
        func adjust(_ item: GlobalAccessionTier, value: Double) -> Double
    }

    final class PercentGlobalAccessionTierAdjuster: GlobalAccessionTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAccessionTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalAccessionTierAdjuster: GlobalAccessionTierFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAccessionTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LocaleGlobalAccessionTierAdjuster: GlobalAccessionTierFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: GlobalAccessionTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global accession tier steps in order and keeps a trace of each.
    final class GlobalAccessionTierEngine {
        var steps: [any GlobalAccessionTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAccessionTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalAccessionTier) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [GlobalAccessionTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalAccessionTierEngine() -> GlobalAccessionTierEngine {
        return GlobalAccessionTierEngine(
            steps: [
                PercentGlobalAccessionTierAdjuster(percent: -2.2),
                TieredGlobalAccessionTierAdjuster(
                    bounds: [1412.0, 2081.0, 3207.0, 8857.0],
                    rates: [0.92, 1.05, 1.17, 0.88]
                ),
                LocaleGlobalAccessionTierAdjuster(factors: ["central": 1.16, "east": 1.32, "west": 1.08]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 95780.1
        )
    }
}
