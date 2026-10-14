import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim snapshot calculation.
    protocol ClaimSnapshotStep {
        func describe() -> String
        func adjust(_ item: ClaimSnapshot, value: Double) -> Double
    }

    final class RoundingClaimSnapshotAdjuster: ClaimSnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedClaimSnapshotAdjuster: ClaimSnapshotStep {
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

        func adjust(_ item: ClaimSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionClaimSnapshotAdjuster: ClaimSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ClaimSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumClaimSnapshotAdjuster: ClaimSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentClaimSnapshotAdjuster: ClaimSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapClaimSnapshotAdjuster: ClaimSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the claim snapshot steps in order and keeps a trace of each.
    final class ClaimSnapshotEngine {
        var steps: [any ClaimSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClaimSnapshot) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ClaimSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClaimSnapshotEngine(_ flags: Kit.Flags.Registry) -> ClaimSnapshotEngine {
        return ClaimSnapshotEngine(
            steps: [
                RoundingClaimSnapshotAdjuster(step: 0.25),
                FlaggedClaimSnapshotAdjuster(flags: flags, flag: "claim-snapshot-fallback", percent: 2.6),
                RegionClaimSnapshotAdjuster(factors: ["retail": 0.82]),
                MinimumClaimSnapshotAdjuster(minimum: 45.8),
                PercentClaimSnapshotAdjuster(percent: -0.9),
                CapClaimSnapshotAdjuster(cap: 21983.0),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 25285.4
        )
    }
}
