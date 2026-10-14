import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict care protocol threshold calculation.
    protocol StrictCareProtocolThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double
    }

    final class SegmentStrictCareProtocolThresholdAdjuster: StrictCareProtocolThresholdAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStrictCareProtocolThresholdAdjuster: StrictCareProtocolThresholdAdjuster {
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

        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictCareProtocolThresholdAdjuster: StrictCareProtocolThresholdAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCareProtocolThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict care protocol threshold steps in order and keeps a trace of each.
    final class StrictCareProtocolThresholdEngine {
        var steps: [any StrictCareProtocolThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCareProtocolThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictCareProtocolThreshold) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [StrictCareProtocolThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictCareProtocolThresholdEngine(_ flags: Kit.Flags.Registry) -> StrictCareProtocolThresholdEngine {
        return StrictCareProtocolThresholdEngine(
            steps: [
                SegmentStrictCareProtocolThresholdAdjuster(factors: ["retail": 0.89, "central": 1.04, "south": 0.71]),
                FlaggedStrictCareProtocolThresholdAdjuster(
                    flags: flags,
                    flag: "strict-care-protocol-threshold-tiered",
                    percent: -4.7
                ),
                RoundingStrictCareProtocolThresholdAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 9624.6
        )
    }
}
