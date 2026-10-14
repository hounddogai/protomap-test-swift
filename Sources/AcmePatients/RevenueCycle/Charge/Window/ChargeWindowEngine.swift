import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge window calculation.
    protocol ChargeWindowModifier {
        func describe() -> String
        func adjust(_ item: ChargeWindow, value: Double) -> Double
    }

    final class CapChargeWindowAdjuster: ChargeWindowModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ChargeWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChargeWindowDosageMgOffsetAdjuster: ChargeWindowModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ChargeWindow, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class FlaggedChargeWindowAdjuster: ChargeWindowModifier {
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

        func adjust(_ item: ChargeWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumChargeWindowAdjuster: ChargeWindowModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredChargeWindowAdjuster: ChargeWindowModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentChargeWindowAdjuster: ChargeWindowModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge window steps in order and keeps a trace of each.
    final class ChargeWindowEngine {
        var steps: [any ChargeWindowModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeWindowModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeWindow) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeWindowModifier = steps[index]
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

        func evaluateAll(_ items: [ChargeWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeWindowEngine(_ flags: Kit.Flags.Registry) -> ChargeWindowEngine {
        return ChargeWindowEngine(
            steps: [
                CapChargeWindowAdjuster(cap: 28793.0),
                ChargeWindowDosageMgOffsetAdjuster(weight: 1.39),
                FlaggedChargeWindowAdjuster(flags: flags, flag: "charge-window-weighted", percent: 7.9),
                MinimumChargeWindowAdjuster(minimum: 42.4),
                TieredChargeWindowAdjuster(bounds: [2867.0, 4549.0, 9196.0], rates: [0.84, 0.86, 1.15]),
                PercentChargeWindowAdjuster(percent: -14.9),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 56472.4
        )
    }
}
