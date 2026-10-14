import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient program variance calculation.
    protocol LenientProgramVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: LenientProgramVariance, value: Double) -> Double
    }

    final class PercentLenientProgramVarianceAdjuster: LenientProgramVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientProgramVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientProgramVarianceAdjuster: LenientProgramVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProgramVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientProgramVarianceAdjuster: LenientProgramVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProgramVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLenientProgramVarianceAdjuster: LenientProgramVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientProgramVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LenientProgramVarianceThresholdOffsetAdjuster: LenientProgramVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LenientProgramVariance, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class TieredLenientProgramVarianceAdjuster: LenientProgramVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientProgramVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient program variance steps in order and keeps a trace of each.
    final class LenientProgramVarianceEngine {
        var steps: [any LenientProgramVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProgramVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientProgramVariance) -> Double {
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

        func evaluateAll(_ items: [LenientProgramVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientProgramVarianceEngine() -> LenientProgramVarianceEngine {
        return LenientProgramVarianceEngine(
            steps: [
                PercentLenientProgramVarianceAdjuster(percent: -20.9),
                RoundingLenientProgramVarianceAdjuster(step: 5.0),
                CapLenientProgramVarianceAdjuster(cap: 29138.0),
                MinimumLenientProgramVarianceAdjuster(minimum: 15.5),
                LenientProgramVarianceThresholdOffsetAdjuster(weight: 1.67),
                TieredLenientProgramVarianceAdjuster(
                    bounds: [1128.0, 8058.0, 8612.0, 8883.0],
                    rates: [1.1, 0.89, 0.89, 0.89]
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 67224.5
        )
    }
}
