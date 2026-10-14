import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending result metric calculation.
    protocol PendingResultMetricModifier {
        func describe() -> String
        func adjust(_ item: PendingResultMetric, value: Double) -> Double
    }

    final class PercentPendingResultMetricAdjuster: PendingResultMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingResultMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingResultMetricFloorValueOffsetAdjuster: PendingResultMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: PendingResultMetric, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class FlaggedPendingResultMetricAdjuster: PendingResultMetricModifier {
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

        func adjust(_ item: PendingResultMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingResultMetricAdjuster: PendingResultMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingResultMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelPendingResultMetricAdjuster: PendingResultMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PendingResultMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending result metric steps in order and keeps a trace of each.
    final class PendingResultMetricEngine {
        var steps: [any PendingResultMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingResultMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingResultMetric) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingResultMetricModifier = steps[index]
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

        func evaluateAll(_ items: [PendingResultMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingResultMetricEngine(_ flags: Kit.Flags.Registry) -> PendingResultMetricEngine {
        return PendingResultMetricEngine(
            steps: [
                PercentPendingResultMetricAdjuster(percent: 21.5),
                PendingResultMetricFloorValueOffsetAdjuster(weight: 1.43),
                FlaggedPendingResultMetricAdjuster(flags: flags, flag: "pending-result-metric-batched", percent: -9.0),
                RoundingPendingResultMetricAdjuster(step: 0.1),
                ChannelPendingResultMetricAdjuster(factors: ["online": 0.97, "north": 1.34]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 61032.5
        )
    }
}
