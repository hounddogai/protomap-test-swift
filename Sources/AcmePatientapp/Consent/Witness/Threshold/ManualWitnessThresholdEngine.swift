import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual witness threshold calculation.
    protocol ManualWitnessThresholdStep {
        func describe() -> String
        func adjust(_ item: ManualWitnessThreshold, value: Double) -> Double
    }

    final class LocaleManualWitnessThresholdAdjuster: ManualWitnessThresholdStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ManualWitnessThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredManualWitnessThresholdAdjuster: ManualWitnessThresholdStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualWitnessThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualWitnessThresholdAdjuster: ManualWitnessThresholdStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualWitnessThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualWitnessThresholdStartsAtOffsetAdjuster: ManualWitnessThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: ManualWitnessThreshold, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingManualWitnessThresholdAdjuster: ManualWitnessThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualWitnessThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual witness threshold steps in order and keeps a trace of each.
    final class ManualWitnessThresholdEngine {
        var steps: [any ManualWitnessThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualWitnessThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualWitnessThreshold) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualWitnessThresholdStep = steps[index]
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

        func evaluateAll(_ items: [ManualWitnessThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualWitnessThresholdEngine() -> ManualWitnessThresholdEngine {
        return ManualWitnessThresholdEngine(
            steps: [
                LocaleManualWitnessThresholdAdjuster(factors: ["east": 1.3, "retail": 1.06]),
                TieredManualWitnessThresholdAdjuster(
                    bounds: [2488.0, 3250.0, 4055.0, 6110.0],
                    rates: [0.91, 1.03, 0.9, 0.86]
                ),
                CapManualWitnessThresholdAdjuster(cap: 32672.0),
                ManualWitnessThresholdStartsAtOffsetAdjuster(weight: 0.21),
                RoundingManualWitnessThresholdAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 59773.5
        )
    }
}
