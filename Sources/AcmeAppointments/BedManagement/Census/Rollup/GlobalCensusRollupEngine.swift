import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global census rollup calculation.
    protocol GlobalCensusRollupAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalCensusRollup, value: Double) -> Double
    }

    final class PercentGlobalCensusRollupAdjuster: GlobalCensusRollupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCensusRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalCensusRollupAdjuster: GlobalCensusRollupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCensusRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalCensusRollupDosageMgOffsetAdjuster: GlobalCensusRollupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: GlobalCensusRollup, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class RoundingGlobalCensusRollupAdjuster: GlobalCensusRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCensusRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGlobalCensusRollupAdjuster: GlobalCensusRollupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCensusRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameGlobalCensusRollupAdjuster: GlobalCensusRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalCensusRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global census rollup steps in order and keeps a trace of each.
    final class GlobalCensusRollupEngine {
        var steps: [any GlobalCensusRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCensusRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalCensusRollup) -> Double {
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

        func evaluateAll(_ items: [GlobalCensusRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalCensusRollupEngine() -> GlobalCensusRollupEngine {
        return GlobalCensusRollupEngine(
            steps: [
                PercentGlobalCensusRollupAdjuster(percent: -4.2),
                CapGlobalCensusRollupAdjuster(cap: 10777.0),
                GlobalCensusRollupDosageMgOffsetAdjuster(weight: 1.88),
                RoundingGlobalCensusRollupAdjuster(step: 0.25),
                TieredGlobalCensusRollupAdjuster(bounds: [2242.0, 5197.0, 8935.0], rates: [0.97, 0.95, 1.02]),
                NameGlobalCensusRollupAdjuster(factors: ["north": 1.06]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 88306.8
        )
    }
}
