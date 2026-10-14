import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered charge variance calculation.
    protocol TieredChargeVarianceModifier {
        func describe() -> String
        func adjust(_ item: TieredChargeVariance, value: Double) -> Double
    }

    final class RoundingTieredChargeVarianceAdjuster: TieredChargeVarianceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredChargeVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentTieredChargeVarianceAdjuster: TieredChargeVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredChargeVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleTieredChargeVarianceAdjuster: TieredChargeVarianceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: TieredChargeVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredChargeVarianceAdjuster: TieredChargeVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredChargeVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the tiered charge variance steps in order and keeps a trace of each.
    final class TieredChargeVarianceEngine {
        var steps: [any TieredChargeVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredChargeVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredChargeVariance) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [TieredChargeVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredChargeVarianceEngine() -> TieredChargeVarianceEngine {
        return TieredChargeVarianceEngine(
            steps: [
                RoundingTieredChargeVarianceAdjuster(step: 0.25),
                PercentTieredChargeVarianceAdjuster(percent: 6.6),
                TitleTieredChargeVarianceAdjuster(factors: ["online": 0.89, "south": 0.8]),
                CapTieredChargeVarianceAdjuster(cap: 1569.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 21345.5
        )
    }
}
