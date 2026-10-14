import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual witness tier calculation.
    protocol ManualWitnessTierStep {
        func describe() -> String
        func adjust(_ item: ManualWitnessTier, value: Double) -> Double
    }

    final class PercentManualWitnessTierAdjuster: ManualWitnessTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualWitnessTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleManualWitnessTierAdjuster: ManualWitnessTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ManualWitnessTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualWitnessTierAdjuster: ManualWitnessTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualWitnessTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ManualWitnessTierBatchSizeOffsetAdjuster: ManualWitnessTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ManualWitnessTier, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class MinimumManualWitnessTierAdjuster: ManualWitnessTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualWitnessTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualWitnessTierAdjuster: ManualWitnessTierStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualWitnessTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual witness tier steps in order and keeps a trace of each.
    final class ManualWitnessTierEngine {
        var steps: [any ManualWitnessTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualWitnessTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualWitnessTier) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualWitnessTierStep = steps[index]
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

        func evaluateAll(_ items: [ManualWitnessTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualWitnessTierEngine() -> ManualWitnessTierEngine {
        return ManualWitnessTierEngine(
            steps: [
                PercentManualWitnessTierAdjuster(percent: -2.9),
                TitleManualWitnessTierAdjuster(factors: ["retail": 1.13, "west": 1.21]),
                RoundingManualWitnessTierAdjuster(step: 0.05),
                ManualWitnessTierBatchSizeOffsetAdjuster(weight: 1.7),
                MinimumManualWitnessTierAdjuster(minimum: 33.8),
                TieredManualWitnessTierAdjuster(bounds: [291.0, 6467.0, 8238.0], rates: [1.06, 0.88, 0.94]),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 51878.9
        )
    }
}
