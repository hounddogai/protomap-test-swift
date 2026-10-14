import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift profile calculation.
    protocol ShiftProfileStep {
        func describe() -> String
        func adjust(_ item: ShiftProfile, value: Double) -> Double
    }

    final class PercentShiftProfileAdjuster: ShiftProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredShiftProfileAdjuster: ShiftProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingShiftProfileAdjuster: ShiftProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedShiftProfileAdjuster: ShiftProfileStep {
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

        func adjust(_ item: ShiftProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the shift profile steps in order and keeps a trace of each.
    final class ShiftProfileEngine {
        var steps: [any ShiftProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ShiftProfile) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [ShiftProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultShiftProfileEngine(_ flags: Kit.Flags.Registry) -> ShiftProfileEngine {
        return ShiftProfileEngine(
            steps: [
                PercentShiftProfileAdjuster(percent: 0.7),
                TieredShiftProfileAdjuster(bounds: [5311.0, 8250.0], rates: [0.99, 0.93]),
                RoundingShiftProfileAdjuster(step: 0.5),
                FlaggedShiftProfileAdjuster(flags: flags, flag: "shift-profile-manual", percent: -5.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 26288.7
        )
    }
}
