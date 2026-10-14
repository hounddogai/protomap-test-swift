import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift window calculation.
    protocol ShiftWindowStep {
        func describe() -> String
        func adjust(_ item: ShiftWindow, value: Double) -> Double
    }

    final class FlaggedShiftWindowAdjuster: ShiftWindowStep {
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

        func adjust(_ item: ShiftWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ShiftWindowVersionOffsetAdjuster: ShiftWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: ShiftWindow, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class TieredShiftWindowAdjuster: ShiftWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapShiftWindowAdjuster: ShiftWindowStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingShiftWindowAdjuster: ShiftWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the shift window steps in order and keeps a trace of each.
    final class ShiftWindowEngine {
        var steps: [any ShiftWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ShiftWindow) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [ShiftWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultShiftWindowEngine(_ flags: Kit.Flags.Registry) -> ShiftWindowEngine {
        return ShiftWindowEngine(
            steps: [
                FlaggedShiftWindowAdjuster(flags: flags, flag: "shift-window-weighted", percent: 8.9),
                ShiftWindowVersionOffsetAdjuster(weight: 0.86),
                TieredShiftWindowAdjuster(bounds: [1258.0, 3209.0], rates: [1.15, 0.84]),
                CapShiftWindowAdjuster(cap: 30310.0),
                RoundingShiftWindowAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 40374.9
        )
    }
}
