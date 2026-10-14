import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the weighted charge claim calculation.
    protocol WeightedChargeClaimModifier {
        func describe() -> String
        func adjust(_ item: WeightedChargeClaim, value: Double) -> Double
    }

    final class NameWeightedChargeClaimAdjuster: WeightedChargeClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WeightedChargeClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWeightedChargeClaimAdjuster: WeightedChargeClaimModifier {
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

        func adjust(_ item: WeightedChargeClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedChargeClaimAdjuster: WeightedChargeClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedChargeClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapWeightedChargeClaimAdjuster: WeightedChargeClaimModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedChargeClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingWeightedChargeClaimAdjuster: WeightedChargeClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedChargeClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted charge claim steps in order and keeps a trace of each.
    final class WeightedChargeClaimEngine {
        var steps: [any WeightedChargeClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedChargeClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedChargeClaim) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedChargeClaimModifier = steps[index]
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

        func evaluateAll(_ items: [WeightedChargeClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedChargeClaimEngine(_ flags: Kit.Flags.Registry) -> WeightedChargeClaimEngine {
        return WeightedChargeClaimEngine(
            steps: [
                NameWeightedChargeClaimAdjuster(factors: ["east": 1.01, "south": 1.1]),
                FlaggedWeightedChargeClaimAdjuster(
                    flags: flags,
                    flag: "weighted-charge-claim-seasonal",
                    percent: -0.2
                ),
                MinimumWeightedChargeClaimAdjuster(minimum: 19.5),
                CapWeightedChargeClaimAdjuster(cap: 5954.0),
                RoundingWeightedChargeClaimAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 94417.3
        )
    }
}
