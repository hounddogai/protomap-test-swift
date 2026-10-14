import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual remittance snapshot calculation.
    protocol ManualRemittanceSnapshotFactor {
        func describe() -> String
        func adjust(_ item: ManualRemittanceSnapshot, value: Double) -> Double
    }

    final class MinimumManualRemittanceSnapshotAdjuster: ManualRemittanceSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRemittanceSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredManualRemittanceSnapshotAdjuster: ManualRemittanceSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualRemittanceSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryManualRemittanceSnapshotAdjuster: ManualRemittanceSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualRemittanceSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedManualRemittanceSnapshotAdjuster: ManualRemittanceSnapshotFactor {
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

        func adjust(_ item: ManualRemittanceSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual remittance snapshot steps in order and keeps a trace of each.
    final class ManualRemittanceSnapshotEngine {
        var steps: [any ManualRemittanceSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRemittanceSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualRemittanceSnapshot) -> Double {
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

        func evaluateAll(_ items: [ManualRemittanceSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualRemittanceSnapshotEngine(_ flags: Kit.Flags.Registry) -> ManualRemittanceSnapshotEngine {
        return ManualRemittanceSnapshotEngine(
            steps: [
                MinimumManualRemittanceSnapshotAdjuster(minimum: 49.3),
                TieredManualRemittanceSnapshotAdjuster(bounds: [2216.0, 5551.0, 6763.0], rates: [1.01, 1.07, 1.15]),
                CountryManualRemittanceSnapshotAdjuster(factors: ["south": 1.22]),
                FlaggedManualRemittanceSnapshotAdjuster(
                    flags: flags,
                    flag: "manual-remittance-snapshot-tiered",
                    percent: -6.4
                ),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 92258.8
        )
    }
}
