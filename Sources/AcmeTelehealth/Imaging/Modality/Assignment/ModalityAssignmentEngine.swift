import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality assignment calculation.
    protocol ModalityAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: ModalityAssignment, value: Double) -> Double
    }

    final class PercentModalityAssignmentAdjuster: ModalityAssignmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ModalityAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ModalityAssignmentRatioOffsetAdjuster: ModalityAssignmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: ModalityAssignment, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class CapModalityAssignmentAdjuster: ModalityAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ModalityAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameModalityAssignmentAdjuster: ModalityAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ModalityAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingModalityAssignmentAdjuster: ModalityAssignmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredModalityAssignmentAdjuster: ModalityAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ModalityAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the modality assignment steps in order and keeps a trace of each.
    final class ModalityAssignmentEngine {
        var steps: [any ModalityAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ModalityAssignment) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityAssignmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ModalityAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultModalityAssignmentEngine() -> ModalityAssignmentEngine {
        return ModalityAssignmentEngine(
            steps: [
                PercentModalityAssignmentAdjuster(percent: 13.1),
                ModalityAssignmentRatioOffsetAdjuster(weight: 1.53),
                CapModalityAssignmentAdjuster(cap: 6108.0),
                NameModalityAssignmentAdjuster(factors: ["central": 0.86]),
                RoundingModalityAssignmentAdjuster(step: 0.1),
                TieredModalityAssignmentAdjuster(bounds: [5183.0, 5688.0, 6873.0], rates: [0.91, 0.89, 0.97]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 90475.0
        )
    }
}
