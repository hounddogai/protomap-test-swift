import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert digest calculation.
    protocol AlertDigestModifier {
        func describe() -> String
        func adjust(_ item: AlertDigest, value: Double) -> Double
    }

    final class PercentAlertDigestAdjuster: AlertDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAlertDigestAdjuster: AlertDigestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAlertDigestAdjuster: AlertDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AlertDigestVisitMinutesOffsetAdjuster: AlertDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: AlertDigest, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    /// Runs the alert digest steps in order and keeps a trace of each.
    final class AlertDigestEngine {
        var steps: [any AlertDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AlertDigest) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertDigestModifier = steps[index]
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

        func evaluateAll(_ items: [AlertDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAlertDigestEngine() -> AlertDigestEngine {
        return AlertDigestEngine(
            steps: [
                PercentAlertDigestAdjuster(percent: 9.5),
                TieredAlertDigestAdjuster(bounds: [6545.0, 7863.0, 8811.0, 9227.0], rates: [0.93, 1.16, 0.84, 1.19]),
                MinimumAlertDigestAdjuster(minimum: 10.6),
                AlertDigestVisitMinutesOffsetAdjuster(weight: 1.88),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 59022.4
        )
    }
}
