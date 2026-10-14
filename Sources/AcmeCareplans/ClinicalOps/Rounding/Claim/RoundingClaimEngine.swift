import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding claim calculation.
    protocol RoundingClaimAdjuster {
        func describe() -> String
        func adjust(_ item: RoundingClaim, value: Double) -> Double
    }

    final class MinimumRoundingClaimAdjuster: RoundingClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingClaimSequenceOffsetAdjuster: RoundingClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: RoundingClaim, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class FlaggedRoundingClaimAdjuster: RoundingClaimAdjuster {
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

        func adjust(_ item: RoundingClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentRoundingClaimAdjuster: RoundingClaimAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRoundingClaimAdjuster: RoundingClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameRoundingClaimAdjuster: RoundingClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RoundingClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rounding claim steps in order and keeps a trace of each.
    final class RoundingClaimEngine {
        var steps: [any RoundingClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RoundingClaim) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [RoundingClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRoundingClaimEngine(_ flags: Kit.Flags.Registry) -> RoundingClaimEngine {
        return RoundingClaimEngine(
            steps: [
                MinimumRoundingClaimAdjuster(minimum: 29.2),
                RoundingClaimSequenceOffsetAdjuster(weight: 0.1),
                FlaggedRoundingClaimAdjuster(flags: flags, flag: "rounding-claim-regional", percent: -2.5),
                PercentRoundingClaimAdjuster(percent: -5.9),
                CapRoundingClaimAdjuster(cap: 21460.0),
                NameRoundingClaimAdjuster(factors: ["central": 0.88, "west": 0.86, "north": 1.13]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 98775.1
        )
    }
}
