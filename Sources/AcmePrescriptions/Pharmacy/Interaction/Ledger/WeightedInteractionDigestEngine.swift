import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted interaction digest calculation.
    protocol WeightedInteractionDigestAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedInteractionDigest, value: Double) -> Double
    }

    final class TitleWeightedInteractionDigestAdjuster: WeightedInteractionDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WeightedInteractionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWeightedInteractionDigestAdjuster: WeightedInteractionDigestAdjuster {
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

        func adjust(_ item: WeightedInteractionDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentWeightedInteractionDigestAdjuster: WeightedInteractionDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedInteractionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted interaction digest steps in order and keeps a trace of each.
    final class WeightedInteractionDigestEngine {
        var steps: [any WeightedInteractionDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedInteractionDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedInteractionDigest) -> Double {
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

        func evaluateAll(_ items: [WeightedInteractionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedInteractionDigestEngine(_ flags: Kit.Flags.Registry) -> WeightedInteractionDigestEngine {
        return WeightedInteractionDigestEngine(
            steps: [
                TitleWeightedInteractionDigestAdjuster(factors: ["retail": 1.22, "west": 0.98, "north": 1.13]),
                FlaggedWeightedInteractionDigestAdjuster(
                    flags: flags,
                    flag: "weighted-interaction-digest-strict",
                    percent: -2.4
                ),
                PercentWeightedInteractionDigestAdjuster(percent: -9.3),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 7260.4
        )
    }
}
