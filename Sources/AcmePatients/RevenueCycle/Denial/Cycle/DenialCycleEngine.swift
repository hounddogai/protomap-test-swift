import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial cycle calculation.
    protocol DenialCycleStep {
        func describe() -> String
        func adjust(_ item: DenialCycle, value: Double) -> Double
    }

    final class PercentDenialCycleAdjuster: DenialCycleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDenialCycleAdjuster: DenialCycleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardDenialCycleAdjuster: DenialCycleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DenialCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDenialCycleAdjuster: DenialCycleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumDenialCycleAdjuster: DenialCycleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDenialCycleAdjuster: DenialCycleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the denial cycle steps in order and keeps a trace of each.
    final class DenialCycleEngine {
        var steps: [any DenialCycleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialCycleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialCycle) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [DenialCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialCycleEngine() -> DenialCycleEngine {
        return DenialCycleEngine(
            steps: [
                PercentDenialCycleAdjuster(percent: -5.4),
                RoundingDenialCycleAdjuster(step: 0.1),
                WardDenialCycleAdjuster(factors: ["north": 0.98]),
                CapDenialCycleAdjuster(cap: 27720.0),
                MinimumDenialCycleAdjuster(minimum: 29.4),
                TieredDenialCycleAdjuster(bounds: [1864.0, 2356.0, 8548.0, 9337.0], rates: [0.98, 1.11, 1.04, 0.8]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 7158.1
        )
    }
}
