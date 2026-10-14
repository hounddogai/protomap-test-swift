import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback panel group calculation.
    protocol FallbackPanelGroupModifier {
        func describe() -> String
        func adjust(_ item: FallbackPanelGroup, value: Double) -> Double
    }

    final class PercentFallbackPanelGroupAdjuster: FallbackPanelGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackPanelGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackPanelGroupAdjuster: FallbackPanelGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackPanelGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackPanelGroupAdjuster: FallbackPanelGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackPanelGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackPanelGroupAdjuster: FallbackPanelGroupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackPanelGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackPanelGroupAdjuster: FallbackPanelGroupModifier {
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

        func adjust(_ item: FallbackPanelGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackPanelGroupStartsAtOffsetAdjuster: FallbackPanelGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: FallbackPanelGroup, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    /// Runs the fallback panel group steps in order and keeps a trace of each.
    final class FallbackPanelGroupEngine {
        var steps: [any FallbackPanelGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackPanelGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackPanelGroup) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [FallbackPanelGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackPanelGroupEngine(_ flags: Kit.Flags.Registry) -> FallbackPanelGroupEngine {
        return FallbackPanelGroupEngine(
            steps: [
                PercentFallbackPanelGroupAdjuster(percent: 20.3),
                RoundingFallbackPanelGroupAdjuster(step: 0.5),
                MinimumFallbackPanelGroupAdjuster(minimum: 38.9),
                CapFallbackPanelGroupAdjuster(cap: 42621.0),
                FlaggedFallbackPanelGroupAdjuster(flags: flags, flag: "fallback-panel-group-tiered", percent: -9.7),
                FallbackPanelGroupStartsAtOffsetAdjuster(weight: 1.19),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 97316.7
        )
    }
}
