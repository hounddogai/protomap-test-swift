import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual bed board window calculation.
    protocol ManualBedBoardWindowStep {
        func describe() -> String
        func adjust(_ item: ManualBedBoardWindow, value: Double) -> Double
    }

    final class RoundingManualBedBoardWindowAdjuster: ManualBedBoardWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualBedBoardWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualBedBoardWindowAdjuster: ManualBedBoardWindowStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualBedBoardWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualBedBoardWindowAdjuster: ManualBedBoardWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualBedBoardWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelManualBedBoardWindowAdjuster: ManualBedBoardWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualBedBoardWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentManualBedBoardWindowAdjuster: ManualBedBoardWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualBedBoardWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedManualBedBoardWindowAdjuster: ManualBedBoardWindowStep {
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

        func adjust(_ item: ManualBedBoardWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual bed board window steps in order and keeps a trace of each.
    final class ManualBedBoardWindowEngine {
        var steps: [any ManualBedBoardWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualBedBoardWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ManualBedBoardWindow) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ManualBedBoardWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultManualBedBoardWindowEngine(_ flags: Kit.Flags.Registry) -> ManualBedBoardWindowEngine {
        return ManualBedBoardWindowEngine(
            steps: [
                RoundingManualBedBoardWindowAdjuster(step: 0.25),
                MinimumManualBedBoardWindowAdjuster(minimum: 44.5),
                TieredManualBedBoardWindowAdjuster(bounds: [4391.0, 6046.0, 8601.0], rates: [0.89, 1.1, 0.94]),
                LabelManualBedBoardWindowAdjuster(factors: ["east": 0.97]),
                PercentManualBedBoardWindowAdjuster(percent: -16.4),
                FlaggedManualBedBoardWindowAdjuster(
                    flags: flags,
                    flag: "manual-bed-board-window-capped",
                    percent: 5.6
                ),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 23309.5
        )
    }
}
