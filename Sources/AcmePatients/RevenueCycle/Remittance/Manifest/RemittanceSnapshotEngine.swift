import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance snapshot calculation.
    protocol RemittanceSnapshotModifier {
        func describe() -> String
        func adjust(_ item: RemittanceSnapshot, value: Double) -> Double
    }

    final class FacilityRemittanceSnapshotAdjuster: RemittanceSnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RemittanceSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRemittanceSnapshotAdjuster: RemittanceSnapshotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRemittanceSnapshotAdjuster: RemittanceSnapshotModifier {
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

        func adjust(_ item: RemittanceSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the remittance snapshot steps in order and keeps a trace of each.
    final class RemittanceSnapshotEngine {
        var steps: [any RemittanceSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceSnapshot) -> Double {
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

        func evaluateAll(_ items: [RemittanceSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceSnapshotEngine(_ flags: Kit.Flags.Registry) -> RemittanceSnapshotEngine {
        return RemittanceSnapshotEngine(
            steps: [
                FacilityRemittanceSnapshotAdjuster(factors: ["retail": 1.27]),
                PercentRemittanceSnapshotAdjuster(percent: -6.1),
                FlaggedRemittanceSnapshotAdjuster(flags: flags, flag: "remittance-snapshot-seasonal", percent: 0.5),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 71611.0
        )
    }
}
