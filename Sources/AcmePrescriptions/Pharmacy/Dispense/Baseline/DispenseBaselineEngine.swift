import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the dispense baseline calculation.
    protocol DispenseBaselineStep {
        func describe() -> String
        func adjust(_ item: DispenseBaseline, value: Double) -> Double
    }

    final class RoundingDispenseBaselineAdjuster: DispenseBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DispenseBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DispenseBaselineRatioOffsetAdjuster: DispenseBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: DispenseBaseline, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RegionDispenseBaselineAdjuster: DispenseBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: DispenseBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the dispense baseline steps in order and keeps a trace of each.
    final class DispenseBaselineEngine {
        var steps: [any DispenseBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DispenseBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DispenseBaseline) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DispenseBaselineStep = steps[index]
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

        func evaluateAll(_ items: [DispenseBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDispenseBaselineEngine() -> DispenseBaselineEngine {
        return DispenseBaselineEngine(
            steps: [
                RoundingDispenseBaselineAdjuster(step: 0.5),
                DispenseBaselineRatioOffsetAdjuster(weight: 0.23),
                RegionDispenseBaselineAdjuster(factors: ["online": 0.98]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 52358.1
        )
    }
}
