import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback panel bundle calculation.
    protocol FallbackPanelBundleModifier {
        func describe() -> String
        func adjust(_ item: FallbackPanelBundle, value: Double) -> Double
    }

    final class RoundingFallbackPanelBundleAdjuster: FallbackPanelBundleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackPanelBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFallbackPanelBundleAdjuster: FallbackPanelBundleModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackPanelBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackPanelBundleAdjuster: FallbackPanelBundleModifier {
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

        func adjust(_ item: FallbackPanelBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackPanelBundleAdjuster: FallbackPanelBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackPanelBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback panel bundle steps in order and keeps a trace of each.
    final class FallbackPanelBundleEngine {
        var steps: [any FallbackPanelBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackPanelBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackPanelBundle) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [FallbackPanelBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackPanelBundleEngine(_ flags: Kit.Flags.Registry) -> FallbackPanelBundleEngine {
        return FallbackPanelBundleEngine(
            steps: [
                RoundingFallbackPanelBundleAdjuster(step: 0.05),
                CapFallbackPanelBundleAdjuster(cap: 3069.0),
                FlaggedFallbackPanelBundleAdjuster(flags: flags, flag: "fallback-panel-bundle-weighted", percent: 0.8),
                TieredFallbackPanelBundleAdjuster(bounds: [693.0, 2429.0, 4335.0], rates: [1.06, 0.89, 1.14]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 12244.9
        )
    }
}
