import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert policy calculation.
    protocol AlertPolicyFactor {
        func describe() -> String
        func adjust(_ item: AlertPolicy, value: Double) -> Double
    }

    final class TieredAlertPolicyAdjuster: AlertPolicyFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAlertPolicyAdjuster: AlertPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAlertPolicyAdjuster: AlertPolicyFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameAlertPolicyAdjuster: AlertPolicyFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AlertPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AlertPolicyExpiresAtOffsetAdjuster: AlertPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: AlertPolicy, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the alert policy steps in order and keeps a trace of each.
    final class AlertPolicyEngine {
        var steps: [any AlertPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AlertPolicy) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [AlertPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAlertPolicyEngine() -> AlertPolicyEngine {
        return AlertPolicyEngine(
            steps: [
                TieredAlertPolicyAdjuster(bounds: [635.0, 3856.0, 4009.0], rates: [0.83, 0.98, 1.04]),
                MinimumAlertPolicyAdjuster(minimum: 43.3),
                CapAlertPolicyAdjuster(cap: 18941.0),
                NameAlertPolicyAdjuster(factors: ["north": 1.19, "south": 1.2, "east": 0.88]),
                AlertPolicyExpiresAtOffsetAdjuster(weight: 0.49),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 40749.7
        )
    }
}
