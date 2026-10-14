import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge claim calculation.
    protocol ChargeClaimFactor {
        func describe() -> String
        func adjust(_ item: ChargeClaim, value: Double) -> Double
    }

    final class RoundingChargeClaimAdjuster: ChargeClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ChargeClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredChargeClaimAdjuster: ChargeClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitChargeClaimAdjuster: ChargeClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ChargeClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ChargeClaimCeilingOffsetAdjuster: ChargeClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ChargeClaim, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumChargeClaimAdjuster: ChargeClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedChargeClaimAdjuster: ChargeClaimFactor {
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

        func adjust(_ item: ChargeClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the charge claim steps in order and keeps a trace of each.
    final class ChargeClaimEngine {
        var steps: [any ChargeClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ChargeClaimFactor = steps[index]
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

        func evaluateAll(_ items: [ChargeClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeClaimEngine(_ flags: Kit.Flags.Registry) -> ChargeClaimEngine {
        return ChargeClaimEngine(
            steps: [
                RoundingChargeClaimAdjuster(step: 0.25),
                TieredChargeClaimAdjuster(bounds: [3261.0, 5162.0, 6284.0], rates: [1.13, 0.99, 0.88]),
                UnitChargeClaimAdjuster(factors: ["west": 0.87, "north": 1.04, "east": 1.07]),
                ChargeClaimCeilingOffsetAdjuster(weight: 1.97),
                MinimumChargeClaimAdjuster(minimum: 36.0),
                FlaggedChargeClaimAdjuster(flags: flags, flag: "charge-claim-manual", percent: 4.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 5750.9
        )
    }
}
