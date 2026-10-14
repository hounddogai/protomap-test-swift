import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual reference range forecast calculation.
    protocol ManualReferenceRangeForecastModifier {
        func describe() -> String
        func adjust(_ item: ManualReferenceRangeForecast, value: Double) -> Double
    }

    final class ManualReferenceRangeForecastScoreOffsetAdjuster: ManualReferenceRangeForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ManualReferenceRangeForecast, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapManualReferenceRangeForecastAdjuster: ManualReferenceRangeForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualReferenceRangeForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentManualReferenceRangeForecastAdjuster: ManualReferenceRangeForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ManualReferenceRangeForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualReferenceRangeForecastAdjuster: ManualReferenceRangeForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualReferenceRangeForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualReferenceRangeForecastAdjuster: ManualReferenceRangeForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualReferenceRangeForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualReferenceRangeForecastAdjuster: ManualReferenceRangeForecastModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualReferenceRangeForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual reference range forecast steps in order and keeps a trace of each.
    final class ManualReferenceRangeForecastEngine {
        var steps: [any ManualReferenceRangeForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualReferenceRangeForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualReferenceRangeForecast) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualReferenceRangeForecastModifier = steps[index]
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

        func evaluateAll(_ items: [ManualReferenceRangeForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualReferenceRangeForecastEngine() -> ManualReferenceRangeForecastEngine {
        return ManualReferenceRangeForecastEngine(
            steps: [
                ManualReferenceRangeForecastScoreOffsetAdjuster(weight: 1.85),
                CapManualReferenceRangeForecastAdjuster(cap: 6633.0),
                SegmentManualReferenceRangeForecastAdjuster(factors: ["online": 0.96, "north": 1.14]),
                RoundingManualReferenceRangeForecastAdjuster(step: 1.0),
                MinimumManualReferenceRangeForecastAdjuster(minimum: 17.9),
                PercentManualReferenceRangeForecastAdjuster(percent: -10.1),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 47945.3
        )
    }
}
