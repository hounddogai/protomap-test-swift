import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional alert tier calculation.
    protocol RegionalAlertTierAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalAlertTier, value: Double) -> Double
    }

    final class LabelRegionalAlertTierAdjuster: RegionalAlertTierAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RegionalAlertTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRegionalAlertTierAdjuster: RegionalAlertTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalAlertTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRegionalAlertTierAdjuster: RegionalAlertTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalAlertTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional alert tier steps in order and keeps a trace of each.
    final class RegionalAlertTierEngine {
        var steps: [any RegionalAlertTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAlertTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalAlertTier) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalAlertTierAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalAlertTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalAlertTierEngine() -> RegionalAlertTierEngine {
        return RegionalAlertTierEngine(
            steps: [
                LabelRegionalAlertTierAdjuster(factors: ["retail": 0.79]),
                MinimumRegionalAlertTierAdjuster(minimum: 19.3),
                PercentRegionalAlertTierAdjuster(percent: -20.1),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 4814.6
        )
    }
}
