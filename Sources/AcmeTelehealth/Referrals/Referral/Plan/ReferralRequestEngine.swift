import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the referral request calculation.
    protocol ReferralRequestModifier {
        func describe() -> String
        func adjust(_ item: ReferralRequest, value: Double) -> Double
    }

    final class CapReferralRequestAdjuster: ReferralRequestModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferralRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedReferralRequestAdjuster: ReferralRequestModifier {
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

        func adjust(_ item: ReferralRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReferralRequestAdjuster: ReferralRequestModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferralRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredReferralRequestAdjuster: ReferralRequestModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferralRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ReferralRequestSequenceOffsetAdjuster: ReferralRequestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: ReferralRequest, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the referral request steps in order and keeps a trace of each.
    final class ReferralRequestEngine {
        var steps: [any ReferralRequestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferralRequestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferralRequest) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ReferralRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferralRequestEngine(_ flags: Kit.Flags.Registry) -> ReferralRequestEngine {
        return ReferralRequestEngine(
            steps: [
                CapReferralRequestAdjuster(cap: 26443.0),
                FlaggedReferralRequestAdjuster(flags: flags, flag: "referral-request-pending", percent: 3.5),
                RoundingReferralRequestAdjuster(step: 0.1),
                TieredReferralRequestAdjuster(
                    bounds: [3913.0, 3947.0, 4166.0, 8479.0],
                    rates: [1.15, 1.2, 0.92, 1.15]
                ),
                ReferralRequestSequenceOffsetAdjuster(weight: 1.54),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 28591.3
        )
    }
}
