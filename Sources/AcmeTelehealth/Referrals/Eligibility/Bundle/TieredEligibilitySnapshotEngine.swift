import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the tiered eligibility snapshot calculation.
    protocol TieredEligibilitySnapshotFactor {
        func describe() -> String
        func adjust(_ item: TieredEligibilitySnapshot, value: Double) -> Double
    }

    final class SourceTieredEligibilitySnapshotAdjuster: TieredEligibilitySnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TieredEligibilitySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredEligibilitySnapshotAdjuster: TieredEligibilitySnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredEligibilitySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedTieredEligibilitySnapshotAdjuster: TieredEligibilitySnapshotFactor {
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

        func adjust(_ item: TieredEligibilitySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredEligibilitySnapshotRatioOffsetAdjuster: TieredEligibilitySnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: TieredEligibilitySnapshot, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    /// Runs the tiered eligibility snapshot steps in order and keeps a trace of each.
    final class TieredEligibilitySnapshotEngine {
        var steps: [any TieredEligibilitySnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredEligibilitySnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TieredEligibilitySnapshot) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [TieredEligibilitySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTieredEligibilitySnapshotEngine(_ flags: Kit.Flags.Registry) -> TieredEligibilitySnapshotEngine {
        return TieredEligibilitySnapshotEngine(
            steps: [
                SourceTieredEligibilitySnapshotAdjuster(factors: ["south": 0.91, "west": 1.37]),
                MinimumTieredEligibilitySnapshotAdjuster(minimum: 15.2),
                FlaggedTieredEligibilitySnapshotAdjuster(
                    flags: flags,
                    flag: "tiered-eligibility-snapshot-regional",
                    percent: 2.8
                ),
                TieredEligibilitySnapshotRatioOffsetAdjuster(weight: 1.64),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 87298.6
        )
    }
}
