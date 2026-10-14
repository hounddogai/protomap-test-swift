import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality adjustment calculation.
    protocol ModalityAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: ModalityAdjustment, value: Double) -> Double
    }

    final class PercentModalityAdjustmentAdjuster: ModalityAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumModalityAdjustmentAdjuster: ModalityAdjustmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ModalityAdjustmentRetriesOffsetAdjuster: ModalityAdjustmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: ModalityAdjustment, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class TieredModalityAdjustmentAdjuster: ModalityAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingModalityAdjustmentAdjuster: ModalityAdjustmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the modality adjustment steps in order and keeps a trace of each.
    final class ModalityAdjustmentEngine {
        var steps: [any ModalityAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ModalityAdjustment) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [ModalityAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultModalityAdjustmentEngine() -> ModalityAdjustmentEngine {
        return ModalityAdjustmentEngine(
            steps: [
                PercentModalityAdjustmentAdjuster(percent: -6.6),
                MinimumModalityAdjustmentAdjuster(minimum: 25.9),
                ModalityAdjustmentRetriesOffsetAdjuster(weight: 0.44),
                TieredModalityAdjustmentAdjuster(bounds: [3759.0, 7270.0], rates: [1.18, 1.05]),
                RoundingModalityAdjustmentAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 64635.7
        )
    }
}
