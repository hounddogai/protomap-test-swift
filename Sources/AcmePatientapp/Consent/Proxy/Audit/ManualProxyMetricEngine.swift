import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual proxy metric calculation.
    protocol ManualProxyMetricAdjuster {
        func describe() -> String
        func adjust(_ item: ManualProxyMetric, value: Double) -> Double
    }

    final class RoundingManualProxyMetricAdjuster: ManualProxyMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualProxyMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualProxyMetricAdjuster: ManualProxyMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualProxyMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ManualProxyMetricAcuityOffsetAdjuster: ManualProxyMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ManualProxyMetric, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the manual proxy metric steps in order and keeps a trace of each.
    final class ManualProxyMetricEngine {
        var steps: [any ManualProxyMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualProxyMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualProxyMetric) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualProxyMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualProxyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualProxyMetricEngine() -> ManualProxyMetricEngine {
        return ManualProxyMetricEngine(
            steps: [
                RoundingManualProxyMetricAdjuster(step: 0.5),
                MinimumManualProxyMetricAdjuster(minimum: 30.1),
                ManualProxyMetricAcuityOffsetAdjuster(weight: 0.92),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 80094.2
        )
    }
}
