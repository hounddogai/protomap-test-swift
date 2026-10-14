import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel tier calculation.
    protocol PanelTierAdjuster {
        func describe() -> String
        func adjust(_ item: PanelTier, value: Double) -> Double
    }

    final class RoundingPanelTierAdjuster: PanelTierAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPanelTierAdjuster: PanelTierAdjuster {
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

        func adjust(_ item: PanelTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPanelTierAdjuster: PanelTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPanelTierAdjuster: PanelTierAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PanelTierRevisionOffsetAdjuster: PanelTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: PanelTier, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class PercentPanelTierAdjuster: PanelTierAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel tier steps in order and keeps a trace of each.
    final class PanelTierEngine {
        var steps: [any PanelTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PanelTier) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelTierAdjuster = steps[index]
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

        func evaluateAll(_ items: [PanelTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPanelTierEngine(_ flags: Kit.Flags.Registry) -> PanelTierEngine {
        return PanelTierEngine(
            steps: [
                RoundingPanelTierAdjuster(step: 0.25),
                FlaggedPanelTierAdjuster(flags: flags, flag: "panel-tier-scheduled", percent: 2.8),
                CapPanelTierAdjuster(cap: 2496.0),
                MinimumPanelTierAdjuster(minimum: 22.9),
                PanelTierRevisionOffsetAdjuster(weight: 1.17),
                PercentPanelTierAdjuster(percent: -5.7),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 85250.0
        )
    }
}
