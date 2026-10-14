import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped order set profile calculation.
    protocol CappedOrderSetProfileModifier {
        func describe() -> String
        func adjust(_ item: CappedOrderSetProfile, value: Double) -> Double
    }

    final class FlaggedCappedOrderSetProfileAdjuster: CappedOrderSetProfileModifier {
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

        func adjust(_ item: CappedOrderSetProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitCappedOrderSetProfileAdjuster: CappedOrderSetProfileModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedOrderSetProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedOrderSetProfileGraceDaysOffsetAdjuster: CappedOrderSetProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: CappedOrderSetProfile, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapCappedOrderSetProfileAdjuster: CappedOrderSetProfileModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedOrderSetProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedOrderSetProfileAdjuster: CappedOrderSetProfileModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedOrderSetProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped order set profile steps in order and keeps a trace of each.
    final class CappedOrderSetProfileEngine {
        var steps: [any CappedOrderSetProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedOrderSetProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedOrderSetProfile) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedOrderSetProfileModifier = steps[index]
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

        func evaluateAll(_ items: [CappedOrderSetProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedOrderSetProfileEngine(_ flags: Kit.Flags.Registry) -> CappedOrderSetProfileEngine {
        return CappedOrderSetProfileEngine(
            steps: [
                FlaggedCappedOrderSetProfileAdjuster(
                    flags: flags,
                    flag: "capped-order-set-profile-default",
                    percent: 2.0
                ),
                UnitCappedOrderSetProfileAdjuster(factors: ["east": 0.89, "north": 0.76, "south": 1.33]),
                CappedOrderSetProfileGraceDaysOffsetAdjuster(weight: 0.44),
                CapCappedOrderSetProfileAdjuster(cap: 3130.0),
                TieredCappedOrderSetProfileAdjuster(bounds: [2022.0, 5899.0], rates: [1.12, 1.05]),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 50044.0
        )
    }
}
