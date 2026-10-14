import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial claim calculation.
    protocol DenialClaimModifier {
        func describe() -> String
        func adjust(_ item: DenialClaim, value: Double) -> Double
    }

    final class TieredDenialClaimAdjuster: DenialClaimModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDenialClaimAdjuster: DenialClaimModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDenialClaimAdjuster: DenialClaimModifier {
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

        func adjust(_ item: DenialClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDenialClaimAdjuster: DenialClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DenialClaimAmountOffsetAdjuster: DenialClaimModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: DenialClaim, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the denial claim steps in order and keeps a trace of each.
    final class DenialClaimEngine {
        var steps: [any DenialClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialClaim) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialClaimModifier = steps[index]
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

        func evaluateAll(_ items: [DenialClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialClaimEngine(_ flags: Kit.Flags.Registry) -> DenialClaimEngine {
        return DenialClaimEngine(
            steps: [
                TieredDenialClaimAdjuster(bounds: [209.0, 3213.0, 8391.0, 8755.0], rates: [0.83, 1.1, 1.1, 1.11]),
                MinimumDenialClaimAdjuster(minimum: 31.1),
                FlaggedDenialClaimAdjuster(flags: flags, flag: "denial-claim-legacy", percent: -0.2),
                RoundingDenialClaimAdjuster(step: 0.25),
                DenialClaimAmountOffsetAdjuster(weight: 0.44),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 76183.0
        )
    }
}
