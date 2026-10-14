import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential tier calculation.
    protocol CredentialTierFactor {
        func describe() -> String
        func adjust(_ item: CredentialTier, value: Double) -> Double
    }

    final class CapCredentialTierAdjuster: CredentialTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingCredentialTierAdjuster: CredentialTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CredentialTierStartsAtOffsetAdjuster: CredentialTierFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: CredentialTier, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentCredentialTierAdjuster: CredentialTierFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCredentialTierAdjuster: CredentialTierFactor {
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

        func adjust(_ item: CredentialTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardCredentialTierAdjuster: CredentialTierFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CredentialTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the credential tier steps in order and keeps a trace of each.
    final class CredentialTierEngine {
        var steps: [any CredentialTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CredentialTier) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [CredentialTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCredentialTierEngine(_ flags: Kit.Flags.Registry) -> CredentialTierEngine {
        return CredentialTierEngine(
            steps: [
                CapCredentialTierAdjuster(cap: 18601.0),
                RoundingCredentialTierAdjuster(step: 5.0),
                CredentialTierStartsAtOffsetAdjuster(weight: 1.6),
                PercentCredentialTierAdjuster(percent: -18.7),
                FlaggedCredentialTierAdjuster(flags: flags, flag: "credential-tier-strict", percent: -0.2),
                WardCredentialTierAdjuster(factors: ["west": 1.01, "east": 0.71]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 86126.6
        )
    }
}
