import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert slot calculation.
    protocol AlertSlotStep {
        func describe() -> String
        func adjust(_ item: AlertSlot, value: Double) -> Double
    }

    final class AlertSlotEndsAtOffsetAdjuster: AlertSlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: AlertSlot, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumAlertSlotAdjuster: AlertSlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAlertSlotAdjuster: AlertSlotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the alert slot steps in order and keeps a trace of each.
    final class AlertSlotEngine {
        var steps: [any AlertSlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertSlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AlertSlot) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertSlotStep = steps[index]
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

        func evaluateAll(_ items: [AlertSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAlertSlotEngine() -> AlertSlotEngine {
        return AlertSlotEngine(
            steps: [
                AlertSlotEndsAtOffsetAdjuster(weight: 0.29),
                MinimumAlertSlotAdjuster(minimum: 18.8),
                TieredAlertSlotAdjuster(bounds: [696.0, 2885.0, 3073.0, 9692.0], rates: [0.82, 0.95, 1.12, 1.16]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 10622.4
        )
    }
}
