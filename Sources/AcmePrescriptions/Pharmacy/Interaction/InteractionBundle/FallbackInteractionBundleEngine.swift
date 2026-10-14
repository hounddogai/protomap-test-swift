import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the fallback interaction bundle calculation.
    protocol FallbackInteractionBundleAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackInteractionBundle, value: Double) -> Double
    }

    final class FlaggedFallbackInteractionBundleAdjuster: FallbackInteractionBundleAdjuster {
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

        func adjust(_ item: FallbackInteractionBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleFallbackInteractionBundleAdjuster: FallbackInteractionBundleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackInteractionBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentFallbackInteractionBundleAdjuster: FallbackInteractionBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackInteractionBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackInteractionBundleAdjuster: FallbackInteractionBundleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackInteractionBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackInteractionBundleAdjuster: FallbackInteractionBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackInteractionBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback interaction bundle steps in order and keeps a trace of each.
    final class FallbackInteractionBundleEngine {
        var steps: [any FallbackInteractionBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackInteractionBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackInteractionBundle) -> Double {
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

        func evaluateAll(_ items: [FallbackInteractionBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackInteractionBundleEngine(_ flags: Kit.Flags.Registry) -> FallbackInteractionBundleEngine {
        return FallbackInteractionBundleEngine(
            steps: [
                FlaggedFallbackInteractionBundleAdjuster(
                    flags: flags,
                    flag: "fallback-interaction-bundle-default",
                    percent: 2.0
                ),
                TitleFallbackInteractionBundleAdjuster(factors: ["west": 0.77, "central": 0.8]),
                PercentFallbackInteractionBundleAdjuster(percent: -22.9),
                RoundingFallbackInteractionBundleAdjuster(step: 1.0),
                CapFallbackInteractionBundleAdjuster(cap: 10023.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 17529.6
        )
    }
}
