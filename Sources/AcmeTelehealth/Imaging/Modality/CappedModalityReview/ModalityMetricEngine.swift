import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality metric calculation.
    protocol ModalityMetricAdjuster {
        func describe() -> String
        func adjust(_ item: ModalityMetric, value: Double) -> Double
    }

    final class PercentModalityMetricAdjuster: ModalityMetricAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumModalityMetricAdjuster: ModalityMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelModalityMetricAdjuster: ModalityMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ModalityMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingModalityMetricAdjuster: ModalityMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ModalityMetricMaximumOffsetAdjuster: ModalityMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: ModalityMetric, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CapModalityMetricAdjuster: ModalityMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the modality metric steps in order and keeps a trace of each.
    final class ModalityMetricEngine {
        var steps: [any ModalityMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ModalityMetric) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [ModalityMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultModalityMetricEngine() -> ModalityMetricEngine {
        return ModalityMetricEngine(
            steps: [
                PercentModalityMetricAdjuster(percent: -2.1),
                MinimumModalityMetricAdjuster(minimum: 28.4),
                LabelModalityMetricAdjuster(factors: ["south": 1.05]),
                RoundingModalityMetricAdjuster(step: 5.0),
                ModalityMetricMaximumOffsetAdjuster(weight: 0.48),
                CapModalityMetricAdjuster(cap: 8560.0),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 48374.2
        )
    }
}
