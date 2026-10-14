import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel target calculation.
    protocol PanelTargetAdjuster {
        func describe() -> String
        func adjust(_ item: PanelTarget, value: Double) -> Double
    }

    final class FlaggedPanelTargetAdjuster: PanelTargetAdjuster {
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

        func adjust(_ item: PanelTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitlePanelTargetAdjuster: PanelTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: PanelTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapPanelTargetAdjuster: PanelTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PanelTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPanelTargetAdjuster: PanelTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel target steps in order and keeps a trace of each.
    final class PanelTargetEngine {
        var steps: [any PanelTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PanelTarget) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [PanelTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPanelTargetEngine(_ flags: Kit.Flags.Registry) -> PanelTargetEngine {
        return PanelTargetEngine(
            steps: [
                FlaggedPanelTargetAdjuster(flags: flags, flag: "panel-target-tiered", percent: 0.9),
                TitlePanelTargetAdjuster(factors: ["retail": 1.37, "east": 1.08, "north": 0.82]),
                CapPanelTargetAdjuster(cap: 1689.0),
                PercentPanelTargetAdjuster(percent: 17.1),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 25409.9
        )
    }
}
