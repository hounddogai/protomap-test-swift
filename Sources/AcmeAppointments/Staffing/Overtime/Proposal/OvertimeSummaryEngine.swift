import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime summary calculation.
    protocol OvertimeSummaryModifier {
        func describe() -> String
        func adjust(_ item: OvertimeSummary, value: Double) -> Double
    }

    final class OvertimeSummaryDiscountOffsetAdjuster: OvertimeSummaryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: OvertimeSummary, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class MinimumOvertimeSummaryAdjuster: OvertimeSummaryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeSummary, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedOvertimeSummaryAdjuster: OvertimeSummaryModifier {
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

        func adjust(_ item: OvertimeSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOvertimeSummaryAdjuster: OvertimeSummaryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingOvertimeSummaryAdjuster: OvertimeSummaryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredOvertimeSummaryAdjuster: OvertimeSummaryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: OvertimeSummary, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the overtime summary steps in order and keeps a trace of each.
    final class OvertimeSummaryEngine {
        var steps: [any OvertimeSummaryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeSummaryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: OvertimeSummary) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [OvertimeSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultOvertimeSummaryEngine(_ flags: Kit.Flags.Registry) -> OvertimeSummaryEngine {
        return OvertimeSummaryEngine(
            steps: [
                OvertimeSummaryDiscountOffsetAdjuster(weight: 0.91),
                MinimumOvertimeSummaryAdjuster(minimum: 12.0),
                FlaggedOvertimeSummaryAdjuster(flags: flags, flag: "overtime-summary-seasonal", percent: -0.2),
                CapOvertimeSummaryAdjuster(cap: 14907.0),
                RoundingOvertimeSummaryAdjuster(step: 0.05),
                TieredOvertimeSummaryAdjuster(
                    bounds: [2211.0, 5725.0, 9414.0, 9592.0],
                    rates: [1.17, 1.11, 1.05, 1.19]
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 67896.4
        )
    }
}
