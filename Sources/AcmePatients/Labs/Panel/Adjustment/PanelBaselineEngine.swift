import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel baseline calculation.
    protocol PanelBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: PanelBaseline, value: Double) -> Double
    }

    final class PanelBaselineAmountOffsetAdjuster: PanelBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: PanelBaseline, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CategoryPanelBaselineAdjuster: PanelBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: PanelBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPanelBaselineAdjuster: PanelBaselineAdjuster {
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

        func adjust(_ item: PanelBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the panel baseline steps in order and keeps a trace of each.
    final class PanelBaselineEngine {
        var steps: [any PanelBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PanelBaseline) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PanelBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [PanelBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPanelBaselineEngine(_ flags: Kit.Flags.Registry) -> PanelBaselineEngine {
        return PanelBaselineEngine(
            steps: [
                PanelBaselineAmountOffsetAdjuster(weight: 1.99),
                CategoryPanelBaselineAdjuster(factors: ["north": 0.89, "south": 0.92, "online": 0.87]),
                FlaggedPanelBaselineAdjuster(flags: flags, flag: "panel-baseline-adaptive", percent: -7.6),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 98555.5
        )
    }
}
