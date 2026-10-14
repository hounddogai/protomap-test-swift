import AcmePlatform
import Foundation

extension Consent {
    /// One step of the tiered revocation baseline calculation.
    protocol TieredRevocationBaselineFactor {
        func describe() -> String
        func adjust(_ item: TieredRevocationBaseline, value: Double) -> Double
    }

    final class TieredRevocationBaselineCopayOffsetAdjuster: TieredRevocationBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: TieredRevocationBaseline, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentTieredRevocationBaselineAdjuster: TieredRevocationBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRevocationBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredRevocationBaselineAdjuster: TieredRevocationBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRevocationBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredRevocationBaselineAdjuster: TieredRevocationBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRevocationBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameTieredRevocationBaselineAdjuster: TieredRevocationBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: TieredRevocationBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredTieredRevocationBaselineAdjuster: TieredRevocationBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredRevocationBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered revocation baseline steps in order and keeps a trace of each.
    final class TieredRevocationBaselineEngine {
        var steps: [any TieredRevocationBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRevocationBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredRevocationBaseline) -> Double {
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

        func evaluateAll(_ items: [TieredRevocationBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredRevocationBaselineEngine() -> TieredRevocationBaselineEngine {
        return TieredRevocationBaselineEngine(
            steps: [
                TieredRevocationBaselineCopayOffsetAdjuster(weight: 1.43),
                PercentTieredRevocationBaselineAdjuster(percent: -17.1),
                CapTieredRevocationBaselineAdjuster(cap: 17897.0),
                MinimumTieredRevocationBaselineAdjuster(minimum: 25.0),
                NameTieredRevocationBaselineAdjuster(factors: ["south": 1.05]),
                TieredTieredRevocationBaselineAdjuster(bounds: [763.0, 1289.0], rates: [0.86, 1.01]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 66523.2
        )
    }
}
