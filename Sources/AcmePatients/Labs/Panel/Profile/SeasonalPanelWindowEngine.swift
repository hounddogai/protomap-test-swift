import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal panel window calculation.
    protocol SeasonalPanelWindowModifier {
        func describe() -> String
        func adjust(_ item: SeasonalPanelWindow, value: Double) -> Double
    }

    final class PercentSeasonalPanelWindowAdjuster: SeasonalPanelWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalPanelWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalPanelWindowAdjuster: SeasonalPanelWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalPanelWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingSeasonalPanelWindowAdjuster: SeasonalPanelWindowModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalPanelWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSeasonalPanelWindowAdjuster: SeasonalPanelWindowModifier {
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

        func adjust(_ item: SeasonalPanelWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalPanelWindowVersionOffsetAdjuster: SeasonalPanelWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: SeasonalPanelWindow, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class NameSeasonalPanelWindowAdjuster: SeasonalPanelWindowModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalPanelWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal panel window steps in order and keeps a trace of each.
    final class SeasonalPanelWindowEngine {
        var steps: [any SeasonalPanelWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalPanelWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalPanelWindow) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalPanelWindowModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalPanelWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalPanelWindowEngine(_ flags: Kit.Flags.Registry) -> SeasonalPanelWindowEngine {
        return SeasonalPanelWindowEngine(
            steps: [
                PercentSeasonalPanelWindowAdjuster(percent: 15.1),
                TieredSeasonalPanelWindowAdjuster(
                    bounds: [3029.0, 3778.0, 4536.0, 8717.0],
                    rates: [1.0, 1.14, 1.15, 0.8]
                ),
                RoundingSeasonalPanelWindowAdjuster(step: 0.5),
                FlaggedSeasonalPanelWindowAdjuster(flags: flags, flag: "seasonal-panel-window-default", percent: 1.5),
                SeasonalPanelWindowVersionOffsetAdjuster(weight: 0.6),
                NameSeasonalPanelWindowAdjuster(factors: ["online": 0.73, "west": 0.87, "south": 1.02]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 67338.9
        )
    }
}
