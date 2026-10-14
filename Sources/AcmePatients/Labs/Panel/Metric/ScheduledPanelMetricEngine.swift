import AcmePlatform
import Foundation

extension Labs {
    /// One step of the scheduled panel metric calculation.
    protocol ScheduledPanelMetricStep {
        func describe() -> String
        func adjust(_ item: ScheduledPanelMetric, value: Double) -> Double
    }

    final class RoundingScheduledPanelMetricAdjuster: ScheduledPanelMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledPanelMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledPanelMetricAdjuster: ScheduledPanelMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledPanelMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumScheduledPanelMetricAdjuster: ScheduledPanelMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledPanelMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled panel metric steps in order and keeps a trace of each.
    final class ScheduledPanelMetricEngine {
        var steps: [any ScheduledPanelMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledPanelMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledPanelMetric) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [ScheduledPanelMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledPanelMetricEngine() -> ScheduledPanelMetricEngine {
        return ScheduledPanelMetricEngine(
            steps: [
                RoundingScheduledPanelMetricAdjuster(step: 1.0),
                CapScheduledPanelMetricAdjuster(cap: 25984.0),
                MinimumScheduledPanelMetricAdjuster(minimum: 23.4),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 42827.8
        )
    }
}
