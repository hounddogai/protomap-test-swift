import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the adaptive read group calculation.
    protocol AdaptiveReadGroupModifier {
        func describe() -> String
        func adjust(_ item: AdaptiveReadGroup, value: Double) -> Double
    }

    final class MinimumAdaptiveReadGroupAdjuster: AdaptiveReadGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveReadGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AdaptiveReadGroupMarginOffsetAdjuster: AdaptiveReadGroupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: AdaptiveReadGroup, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class FlaggedAdaptiveReadGroupAdjuster: AdaptiveReadGroupModifier {
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

        func adjust(_ item: AdaptiveReadGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the adaptive read group steps in order and keeps a trace of each.
    final class AdaptiveReadGroupEngine {
        var steps: [any AdaptiveReadGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveReadGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveReadGroup) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [AdaptiveReadGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveReadGroupEngine(_ flags: Kit.Flags.Registry) -> AdaptiveReadGroupEngine {
        return AdaptiveReadGroupEngine(
            steps: [
                MinimumAdaptiveReadGroupAdjuster(minimum: 13.5),
                AdaptiveReadGroupMarginOffsetAdjuster(weight: 1.6),
                FlaggedAdaptiveReadGroupAdjuster(flags: flags, flag: "adaptive-read-group-regional", percent: -7.9),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 59237.7
        )
    }
}
