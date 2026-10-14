import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual cleaning window calculation.
    protocol ManualCleaningWindowStep {
        func describe() -> String
        func adjust(_ item: ManualCleaningWindow, value: Double) -> Double
    }

    final class RoundingManualCleaningWindowAdjuster: ManualCleaningWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCleaningWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ManualCleaningWindowLimitOffsetAdjuster: ManualCleaningWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ManualCleaningWindow, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class FlaggedManualCleaningWindowAdjuster: ManualCleaningWindowStep {
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

        func adjust(_ item: ManualCleaningWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualCleaningWindowAdjuster: ManualCleaningWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCleaningWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualCleaningWindowAdjuster: ManualCleaningWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualCleaningWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualCleaningWindowAdjuster: ManualCleaningWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCleaningWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual cleaning window steps in order and keeps a trace of each.
    final class ManualCleaningWindowEngine {
        var steps: [any ManualCleaningWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCleaningWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualCleaningWindow) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCleaningWindowStep = steps[index]
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

        func evaluateAll(_ items: [ManualCleaningWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualCleaningWindowEngine(_ flags: Kit.Flags.Registry) -> ManualCleaningWindowEngine {
        return ManualCleaningWindowEngine(
            steps: [
                RoundingManualCleaningWindowAdjuster(step: 5.0),
                ManualCleaningWindowLimitOffsetAdjuster(weight: 0.97),
                FlaggedManualCleaningWindowAdjuster(
                    flags: flags,
                    flag: "manual-cleaning-window-capped",
                    percent: -0.8
                ),
                CapManualCleaningWindowAdjuster(cap: 514.0),
                PercentManualCleaningWindowAdjuster(percent: 12.7),
                TieredManualCleaningWindowAdjuster(bounds: [1754.0, 5356.0], rates: [0.99, 1.08]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 27974.6
        )
    }
}
