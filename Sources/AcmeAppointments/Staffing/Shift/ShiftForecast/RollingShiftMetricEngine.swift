import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the rolling shift metric calculation.
    protocol RollingShiftMetricFactor {
        func describe() -> String
        func adjust(_ item: RollingShiftMetric, value: Double) -> Double
    }

    final class CapRollingShiftMetricAdjuster: RollingShiftMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingShiftMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingRollingShiftMetricAdjuster: RollingShiftMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingShiftMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingShiftMetricAdjuster: RollingShiftMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingShiftMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingShiftMetricRevisionOffsetAdjuster: RollingShiftMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: RollingShiftMetric, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    /// Runs the rolling shift metric steps in order and keeps a trace of each.
    final class RollingShiftMetricEngine {
        var steps: [any RollingShiftMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingShiftMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingShiftMetric) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [RollingShiftMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingShiftMetricEngine() -> RollingShiftMetricEngine {
        return RollingShiftMetricEngine(
            steps: [
                CapRollingShiftMetricAdjuster(cap: 12385.0),
                RoundingRollingShiftMetricAdjuster(step: 5.0),
                PercentRollingShiftMetricAdjuster(percent: 11.1),
                RollingShiftMetricRevisionOffsetAdjuster(weight: 0.27),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 30645.5
        )
    }
}
