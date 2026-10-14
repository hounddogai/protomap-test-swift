import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel rollup calculation.
    protocol PanelRollupAdjuster {
        func describe() -> String
        func adjust(_ item: PanelRollup, value: Double) -> Double
    }

    final class SourcePanelRollupAdjuster: PanelRollupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PanelRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentPanelRollupAdjuster: PanelRollupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PanelRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPanelRollupAdjuster: PanelRollupAdjuster {
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

        func adjust(_ item: PanelRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPanelRollupAdjuster: PanelRollupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the panel rollup steps in order and keeps a trace of each.
    final class PanelRollupEngine {
        var steps: [any PanelRollupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelRollupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PanelRollup) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PanelRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPanelRollupEngine(_ flags: Kit.Flags.Registry) -> PanelRollupEngine {
        return PanelRollupEngine(
            steps: [
                SourcePanelRollupAdjuster(factors: ["east": 0.8, "north": 0.79]),
                PercentPanelRollupAdjuster(percent: 20.6),
                FlaggedPanelRollupAdjuster(flags: flags, flag: "panel-rollup-pending", percent: 5.8),
                RoundingPanelRollupAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 65830.7
        )
    }
}
