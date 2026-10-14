import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel threshold calculation.
    protocol PanelThresholdFactor {
        func describe() -> String
        func adjust(_ item: PanelThreshold, value: Double) -> Double
    }

    final class PanelThresholdAttemptsOffsetAdjuster: PanelThresholdFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: PanelThreshold, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class PercentPanelThresholdAdjuster: PanelThresholdFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPanelThresholdAdjuster: PanelThresholdFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPanelThresholdAdjuster: PanelThresholdFactor {
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

        func adjust(_ item: PanelThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPanelThresholdAdjuster: PanelThresholdFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the panel threshold steps in order and keeps a trace of each.
    final class PanelThresholdEngine {
        var steps: [any PanelThresholdFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelThresholdFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelThreshold) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [PanelThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelThresholdEngine(_ flags: Kit.Flags.Registry) -> PanelThresholdEngine {
        return PanelThresholdEngine(
            steps: [
                PanelThresholdAttemptsOffsetAdjuster(weight: 0.48),
                PercentPanelThresholdAdjuster(percent: -13.3),
                CapPanelThresholdAdjuster(cap: 49990.0),
                FlaggedPanelThresholdAdjuster(flags: flags, flag: "panel-threshold-primary", percent: -2.4),
                MinimumPanelThresholdAdjuster(minimum: 45.3),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 71917.9
        )
    }
}
