import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the weighted task manifest calculation.
    protocol WeightedTaskManifestAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedTaskManifest, value: Double) -> Double
    }

    final class ChannelWeightedTaskManifestAdjuster: WeightedTaskManifestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: WeightedTaskManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentWeightedTaskManifestAdjuster: WeightedTaskManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedTaskManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWeightedTaskManifestAdjuster: WeightedTaskManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedTaskManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingWeightedTaskManifestAdjuster: WeightedTaskManifestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedTaskManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWeightedTaskManifestAdjuster: WeightedTaskManifestAdjuster {
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

        func adjust(_ item: WeightedTaskManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedTaskManifestAdjuster: WeightedTaskManifestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedTaskManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted task manifest steps in order and keeps a trace of each.
    final class WeightedTaskManifestEngine {
        var steps: [any WeightedTaskManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTaskManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedTaskManifest) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedTaskManifestAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedTaskManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedTaskManifestEngine(_ flags: Kit.Flags.Registry) -> WeightedTaskManifestEngine {
        return WeightedTaskManifestEngine(
            steps: [
                ChannelWeightedTaskManifestAdjuster(factors: ["retail": 1.26]),
                PercentWeightedTaskManifestAdjuster(percent: -4.2),
                TieredWeightedTaskManifestAdjuster(bounds: [967.0, 2713.0, 8403.0], rates: [0.91, 1.15, 0.98]),
                RoundingWeightedTaskManifestAdjuster(step: 5.0),
                FlaggedWeightedTaskManifestAdjuster(
                    flags: flags,
                    flag: "weighted-task-manifest-pending",
                    percent: -3.1
                ),
                CapWeightedTaskManifestAdjuster(cap: 20175.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 99285.2
        )
    }
}
