import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive program cycle calculation.
    protocol AdaptiveProgramCycleAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveProgramCycle, value: Double) -> Double
    }

    final class RoundingAdaptiveProgramCycleAdjuster: AdaptiveProgramCycleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveProgramCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameAdaptiveProgramCycleAdjuster: AdaptiveProgramCycleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveProgramCycle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveProgramCycleAdjuster: AdaptiveProgramCycleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveProgramCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAdaptiveProgramCycleAdjuster: AdaptiveProgramCycleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveProgramCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAdaptiveProgramCycleAdjuster: AdaptiveProgramCycleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveProgramCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive program cycle steps in order and keeps a trace of each.
    final class AdaptiveProgramCycleEngine {
        var steps: [any AdaptiveProgramCycleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveProgramCycleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveProgramCycle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AdaptiveProgramCycleAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [AdaptiveProgramCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveProgramCycleEngine() -> AdaptiveProgramCycleEngine {
        return AdaptiveProgramCycleEngine(
            steps: [
                RoundingAdaptiveProgramCycleAdjuster(step: 0.5),
                NameAdaptiveProgramCycleAdjuster(factors: ["north": 1.36, "west": 1.29]),
                TieredAdaptiveProgramCycleAdjuster(bounds: [2141.0, 2703.0, 9458.0], rates: [1.2, 1.19, 1.19]),
                CapAdaptiveProgramCycleAdjuster(cap: 45614.0),
                PercentAdaptiveProgramCycleAdjuster(percent: 14.3),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 29598.3
        )
    }
}
