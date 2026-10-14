import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction bundle calculation.
    protocol InteractionBundleAdjuster {
        func describe() -> String
        func adjust(_ item: InteractionBundle, value: Double) -> Double
    }

    final class RoundingInteractionBundleAdjuster: InteractionBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InteractionBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapInteractionBundleAdjuster: InteractionBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleInteractionBundleAdjuster: InteractionBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: InteractionBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredInteractionBundleAdjuster: InteractionBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InteractionBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentInteractionBundleAdjuster: InteractionBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedInteractionBundleAdjuster: InteractionBundleAdjuster {
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

        func adjust(_ item: InteractionBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the interaction bundle steps in order and keeps a trace of each.
    final class InteractionBundleEngine {
        var steps: [any InteractionBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionBundle) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [InteractionBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionBundleEngine(_ flags: Kit.Flags.Registry) -> InteractionBundleEngine {
        return InteractionBundleEngine(
            steps: [
                RoundingInteractionBundleAdjuster(step: 5.0),
                CapInteractionBundleAdjuster(cap: 5808.0),
                TitleInteractionBundleAdjuster(factors: ["central": 1.23, "retail": 1.23]),
                TieredInteractionBundleAdjuster(
                    bounds: [185.0, 914.0, 5441.0, 9071.0],
                    rates: [1.08, 1.06, 0.9, 0.82]
                ),
                PercentInteractionBundleAdjuster(percent: -21.1),
                FlaggedInteractionBundleAdjuster(flags: flags, flag: "interaction-bundle-seasonal", percent: -7.9),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 89215.7
        )
    }
}
