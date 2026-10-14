import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the interaction claim calculation.
    protocol InteractionClaimFactor {
        func describe() -> String
        func adjust(_ item: InteractionClaim, value: Double) -> Double
    }

    final class InteractionClaimBudgetOffsetAdjuster: InteractionClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: InteractionClaim, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class PercentInteractionClaimAdjuster: InteractionClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InteractionClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedInteractionClaimAdjuster: InteractionClaimFactor {
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

        func adjust(_ item: InteractionClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumInteractionClaimAdjuster: InteractionClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InteractionClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapInteractionClaimAdjuster: InteractionClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InteractionClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelInteractionClaimAdjuster: InteractionClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: InteractionClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the interaction claim steps in order and keeps a trace of each.
    final class InteractionClaimEngine {
        var steps: [any InteractionClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InteractionClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InteractionClaim) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InteractionClaimFactor = steps[index]
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

        func evaluateAll(_ items: [InteractionClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInteractionClaimEngine(_ flags: Kit.Flags.Registry) -> InteractionClaimEngine {
        return InteractionClaimEngine(
            steps: [
                InteractionClaimBudgetOffsetAdjuster(weight: 1.58),
                PercentInteractionClaimAdjuster(percent: -15.5),
                FlaggedInteractionClaimAdjuster(flags: flags, flag: "interaction-claim-pending", percent: 5.9),
                MinimumInteractionClaimAdjuster(minimum: 41.0),
                CapInteractionClaimAdjuster(cap: 1757.0),
                ChannelInteractionClaimAdjuster(factors: ["retail": 1.11, "east": 0.85, "west": 0.98]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 70806.7
        )
    }
}
