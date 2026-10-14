import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the adaptive transfer metric calculation.
    protocol AdaptiveTransferMetricAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveTransferMetric, value: Double) -> Double
    }

    final class CapAdaptiveTransferMetricAdjuster: AdaptiveTransferMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveTransferMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentAdaptiveTransferMetricAdjuster: AdaptiveTransferMetricAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AdaptiveTransferMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAdaptiveTransferMetricAdjuster: AdaptiveTransferMetricAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveTransferMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAdaptiveTransferMetricAdjuster: AdaptiveTransferMetricAdjuster {
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

        func adjust(_ item: AdaptiveTransferMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AdaptiveTransferMetricCostOffsetAdjuster: AdaptiveTransferMetricAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: AdaptiveTransferMetric, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingAdaptiveTransferMetricAdjuster: AdaptiveTransferMetricAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveTransferMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive transfer metric steps in order and keeps a trace of each.
    final class AdaptiveTransferMetricEngine {
        var steps: [any AdaptiveTransferMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveTransferMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveTransferMetric) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [AdaptiveTransferMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveTransferMetricEngine(_ flags: Kit.Flags.Registry) -> AdaptiveTransferMetricEngine {
        return AdaptiveTransferMetricEngine(
            steps: [
                CapAdaptiveTransferMetricAdjuster(cap: 40222.0),
                SegmentAdaptiveTransferMetricAdjuster(factors: ["east": 1.24, "retail": 1.05]),
                PercentAdaptiveTransferMetricAdjuster(percent: -21.9),
                FlaggedAdaptiveTransferMetricAdjuster(
                    flags: flags,
                    flag: "adaptive-transfer-metric-pending",
                    percent: 7.3
                ),
                AdaptiveTransferMetricCostOffsetAdjuster(weight: 1.63),
                RoundingAdaptiveTransferMetricAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 5917.8
        )
    }
}
