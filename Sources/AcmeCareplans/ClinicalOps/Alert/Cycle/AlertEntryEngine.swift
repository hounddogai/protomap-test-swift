import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert entry calculation.
    protocol AlertEntryModifier {
        func describe() -> String
        func adjust(_ item: AlertEntry, value: Double) -> Double
    }

    final class TieredAlertEntryAdjuster: AlertEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAlertEntryAdjuster: AlertEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAlertEntryAdjuster: AlertEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AlertEntryAcuityOffsetAdjuster: AlertEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: AlertEntry, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the alert entry steps in order and keeps a trace of each.
    final class AlertEntryEngine {
        var steps: [any AlertEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AlertEntry) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertEntryModifier = steps[index]
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

        func evaluateAll(_ items: [AlertEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAlertEntryEngine() -> AlertEntryEngine {
        return AlertEntryEngine(
            steps: [
                TieredAlertEntryAdjuster(bounds: [8038.0, 9686.0], rates: [1.02, 0.82]),
                MinimumAlertEntryAdjuster(minimum: 4.7),
                PercentAlertEntryAdjuster(percent: -14.3),
                AlertEntryAcuityOffsetAdjuster(weight: 0.81),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 12848.4
        )
    }
}
