import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback overtime metric calculation.
    protocol FallbackOvertimeMetricStep {
        func describe() -> String
        func adjust(_ item: FallbackOvertimeMetric, value: Double) -> Double
    }

    final class RoundingFallbackOvertimeMetricAdjuster: FallbackOvertimeMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackOvertimeMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackOvertimeMetricQuantityOffsetAdjuster: FallbackOvertimeMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: FallbackOvertimeMetric, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedFallbackOvertimeMetricAdjuster: FallbackOvertimeMetricStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FallbackOvertimeMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameFallbackOvertimeMetricAdjuster: FallbackOvertimeMetricStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackOvertimeMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFallbackOvertimeMetricAdjuster: FallbackOvertimeMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackOvertimeMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback overtime metric steps in order and keeps a trace of each.
    final class FallbackOvertimeMetricEngine {
        var steps: [any FallbackOvertimeMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackOvertimeMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackOvertimeMetric) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FallbackOvertimeMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackOvertimeMetricEngine(_ flags: Kit.Flags.Registry) -> FallbackOvertimeMetricEngine {
        return FallbackOvertimeMetricEngine(
            steps: [
                RoundingFallbackOvertimeMetricAdjuster(step: 0.05),
                FallbackOvertimeMetricQuantityOffsetAdjuster(weight: 0.43),
                FlaggedFallbackOvertimeMetricAdjuster(
                    flags: flags,
                    flag: "fallback-overtime-metric-global",
                    percent: 0.3
                ),
                NameFallbackOvertimeMetricAdjuster(factors: ["retail": 0.88, "central": 1.05, "online": 0.71]),
                MinimumFallbackOvertimeMetricAdjuster(minimum: 16.8),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 84721.8
        )
    }
}
