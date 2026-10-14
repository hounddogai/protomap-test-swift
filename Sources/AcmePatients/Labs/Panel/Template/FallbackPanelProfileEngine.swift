import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback panel profile calculation.
    protocol FallbackPanelProfileStep {
        func describe() -> String
        func adjust(_ item: FallbackPanelProfile, value: Double) -> Double
    }

    final class FlaggedFallbackPanelProfileAdjuster: FallbackPanelProfileStep {
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

        func adjust(_ item: FallbackPanelProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackPanelProfileGraceDaysOffsetAdjuster: FallbackPanelProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: FallbackPanelProfile, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class PercentFallbackPanelProfileAdjuster: FallbackPanelProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackPanelProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback panel profile steps in order and keeps a trace of each.
    final class FallbackPanelProfileEngine {
        var steps: [any FallbackPanelProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackPanelProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackPanelProfile) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackPanelProfileStep = steps[index]
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

        func evaluateAll(_ items: [FallbackPanelProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackPanelProfileEngine(_ flags: Kit.Flags.Registry) -> FallbackPanelProfileEngine {
        return FallbackPanelProfileEngine(
            steps: [
                FlaggedFallbackPanelProfileAdjuster(
                    flags: flags,
                    flag: "fallback-panel-profile-scheduled",
                    percent: -8.2
                ),
                FallbackPanelProfileGraceDaysOffsetAdjuster(weight: 1.57),
                PercentFallbackPanelProfileAdjuster(percent: 15.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 7483.6
        )
    }
}
