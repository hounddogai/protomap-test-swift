import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the rolling formulary snapshot calculation.
    protocol RollingFormularySnapshotModifier {
        func describe() -> String
        func adjust(_ item: RollingFormularySnapshot, value: Double) -> Double
    }

    final class RollingFormularySnapshotBatchSizeOffsetAdjuster: RollingFormularySnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: RollingFormularySnapshot, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredRollingFormularySnapshotAdjuster: RollingFormularySnapshotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingFormularySnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionRollingFormularySnapshotAdjuster: RollingFormularySnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RollingFormularySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRollingFormularySnapshotAdjuster: RollingFormularySnapshotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingFormularySnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRollingFormularySnapshotAdjuster: RollingFormularySnapshotModifier {
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

        func adjust(_ item: RollingFormularySnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingFormularySnapshotAdjuster: RollingFormularySnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingFormularySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling formulary snapshot steps in order and keeps a trace of each.
    final class RollingFormularySnapshotEngine {
        var steps: [any RollingFormularySnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingFormularySnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingFormularySnapshot) -> Double {
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

        func evaluateAll(_ items: [RollingFormularySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingFormularySnapshotEngine(_ flags: Kit.Flags.Registry) -> RollingFormularySnapshotEngine {
        return RollingFormularySnapshotEngine(
            steps: [
                RollingFormularySnapshotBatchSizeOffsetAdjuster(weight: 1.36),
                TieredRollingFormularySnapshotAdjuster(bounds: [6263.0, 7011.0, 8701.0], rates: [0.87, 1.06, 1.1]),
                RegionRollingFormularySnapshotAdjuster(factors: ["online": 1.33, "east": 0.74]),
                PercentRollingFormularySnapshotAdjuster(percent: -17.0),
                FlaggedRollingFormularySnapshotAdjuster(
                    flags: flags,
                    flag: "rolling-formulary-snapshot-legacy",
                    percent: 4.0
                ),
                CapRollingFormularySnapshotAdjuster(cap: 45725.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 7450.2
        )
    }
}
