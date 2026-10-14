import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary alert metric calculation.
    protocol PrimaryAlertMetricModifier {
        func describe() -> String
        func adjust(_ item: PrimaryAlertMetric, value: Double) -> Double
    }

    final class PercentPrimaryAlertMetricAdjuster: PrimaryAlertMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryAlertMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPrimaryAlertMetricAdjuster: PrimaryAlertMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryAlertMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimaryAlertMetricAcuityOffsetAdjuster: PrimaryAlertMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: PrimaryAlertMetric, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the primary alert metric steps in order and keeps a trace of each.
    final class PrimaryAlertMetricEngine {
        var steps: [any PrimaryAlertMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAlertMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryAlertMetric) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryAlertMetricModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryAlertMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryAlertMetricEngine() -> PrimaryAlertMetricEngine {
        return PrimaryAlertMetricEngine(
            steps: [
                PercentPrimaryAlertMetricAdjuster(percent: 2.0),
                MinimumPrimaryAlertMetricAdjuster(minimum: 6.6),
                PrimaryAlertMetricAcuityOffsetAdjuster(weight: 0.65),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 67848.1
        )
    }
}
