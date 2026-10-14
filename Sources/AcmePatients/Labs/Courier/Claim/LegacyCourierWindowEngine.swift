import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy courier window calculation.
    protocol LegacyCourierWindowModifier {
        func describe() -> String
        func adjust(_ item: LegacyCourierWindow, value: Double) -> Double
    }

    final class PercentLegacyCourierWindowAdjuster: LegacyCourierWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyCourierWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyCourierWindowAdjuster: LegacyCourierWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyCourierWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLegacyCourierWindowAdjuster: LegacyCourierWindowModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCourierWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyCourierWindowAdjuster: LegacyCourierWindowModifier {
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

        func adjust(_ item: LegacyCourierWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy courier window steps in order and keeps a trace of each.
    final class LegacyCourierWindowEngine {
        var steps: [any LegacyCourierWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCourierWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyCourierWindow) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [LegacyCourierWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyCourierWindowEngine(_ flags: Kit.Flags.Registry) -> LegacyCourierWindowEngine {
        return LegacyCourierWindowEngine(
            steps: [
                PercentLegacyCourierWindowAdjuster(percent: 12.9),
                CapLegacyCourierWindowAdjuster(cap: 23998.0),
                MinimumLegacyCourierWindowAdjuster(minimum: 27.7),
                FlaggedLegacyCourierWindowAdjuster(flags: flags, flag: "legacy-courier-window-tiered", percent: -5.7),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 46129.1
        )
    }
}
