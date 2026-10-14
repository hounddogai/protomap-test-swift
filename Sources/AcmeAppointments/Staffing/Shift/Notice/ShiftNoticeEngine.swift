import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift notice calculation.
    protocol ShiftNoticeModifier {
        func describe() -> String
        func adjust(_ item: ShiftNotice, value: Double) -> Double
    }

    final class RoundingShiftNoticeAdjuster: ShiftNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredShiftNoticeAdjuster: ShiftNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapShiftNoticeAdjuster: ShiftNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedShiftNoticeAdjuster: ShiftNoticeModifier {
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

        func adjust(_ item: ShiftNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentShiftNoticeAdjuster: ShiftNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumShiftNoticeAdjuster: ShiftNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the shift notice steps in order and keeps a trace of each.
    final class ShiftNoticeEngine {
        var steps: [any ShiftNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftNotice) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ShiftNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftNoticeEngine(_ flags: Kit.Flags.Registry) -> ShiftNoticeEngine {
        return ShiftNoticeEngine(
            steps: [
                RoundingShiftNoticeAdjuster(step: 5.0),
                TieredShiftNoticeAdjuster(bounds: [3478.0, 3531.0], rates: [0.92, 1.08]),
                CapShiftNoticeAdjuster(cap: 10229.0),
                FlaggedShiftNoticeAdjuster(flags: flags, flag: "shift-notice-capped", percent: -9.3),
                PercentShiftNoticeAdjuster(percent: 5.5),
                MinimumShiftNoticeAdjuster(minimum: 37.7),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 90650.0
        )
    }
}
