import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol rollup calculation.
    protocol CareProtocolRollupFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolRollup, value: Double) -> Double
    }

    final class MinimumCareProtocolRollupAdjuster: CareProtocolRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapCareProtocolRollupAdjuster: CareProtocolRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceCareProtocolRollupAdjuster: CareProtocolRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCareProtocolRollupAdjuster: CareProtocolRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care protocol rollup steps in order and keeps a trace of each.
    final class CareProtocolRollupEngine {
        var steps: [any CareProtocolRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CareProtocolRollup) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [CareProtocolRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCareProtocolRollupEngine() -> CareProtocolRollupEngine {
        return CareProtocolRollupEngine(
            steps: [
                MinimumCareProtocolRollupAdjuster(minimum: 3.5),
                CapCareProtocolRollupAdjuster(cap: 47690.0),
                SourceCareProtocolRollupAdjuster(factors: ["online": 1.22, "central": 0.81]),
                TieredCareProtocolRollupAdjuster(bounds: [829.0, 3823.0, 9892.0], rates: [1.07, 0.99, 1.14]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 27176.3
        )
    }
}
