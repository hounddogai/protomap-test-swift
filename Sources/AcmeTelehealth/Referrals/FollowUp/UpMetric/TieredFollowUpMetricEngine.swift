import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered follow up metric calculation.
    protocol TieredFollowUpMetricStep {
        func describe() -> String
        func adjust(_ item: TieredFollowUpMetric, value: Double) -> Double
    }

    final class TieredFollowUpMetricSequenceOffsetAdjuster: TieredFollowUpMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: TieredFollowUpMetric, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class PercentTieredFollowUpMetricAdjuster: TieredFollowUpMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredFollowUpMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredFollowUpMetricAdjuster: TieredFollowUpMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredFollowUpMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedTieredFollowUpMetricAdjuster: TieredFollowUpMetricStep {
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

        func adjust(_ item: TieredFollowUpMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumTieredFollowUpMetricAdjuster: TieredFollowUpMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredFollowUpMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered follow up metric steps in order and keeps a trace of each.
    final class TieredFollowUpMetricEngine {
        var steps: [any TieredFollowUpMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredFollowUpMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredFollowUpMetric) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [TieredFollowUpMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredFollowUpMetricEngine(_ flags: Kit.Flags.Registry) -> TieredFollowUpMetricEngine {
        return TieredFollowUpMetricEngine(
            steps: [
                TieredFollowUpMetricSequenceOffsetAdjuster(weight: 1.5),
                PercentTieredFollowUpMetricAdjuster(percent: -3.9),
                CapTieredFollowUpMetricAdjuster(cap: 13155.0),
                FlaggedTieredFollowUpMetricAdjuster(
                    flags: flags,
                    flag: "tiered-follow-up-metric-lenient",
                    percent: -2.8
                ),
                MinimumTieredFollowUpMetricAdjuster(minimum: 6.2),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 49183.7
        )
    }
}
