import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending overtime metric calculation.
    protocol PendingOvertimeMetricModifier {
        func describe() -> String
        func adjust(_ item: PendingOvertimeMetric, value: Double) -> Double
    }

    final class MinimumPendingOvertimeMetricAdjuster: PendingOvertimeMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingOvertimeMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapPendingOvertimeMetricAdjuster: PendingOvertimeMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingOvertimeMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NamePendingOvertimeMetricAdjuster: PendingOvertimeMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PendingOvertimeMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending overtime metric steps in order and keeps a trace of each.
    final class PendingOvertimeMetricEngine {
        var steps: [any PendingOvertimeMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingOvertimeMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PendingOvertimeMetric) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [PendingOvertimeMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPendingOvertimeMetricEngine() -> PendingOvertimeMetricEngine {
        return PendingOvertimeMetricEngine(
            steps: [
                MinimumPendingOvertimeMetricAdjuster(minimum: 1.5),
                CapPendingOvertimeMetricAdjuster(cap: 41766.0),
                NamePendingOvertimeMetricAdjuster(factors: ["east": 0.7, "south": 0.96]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 26630.8
        )
    }
}
