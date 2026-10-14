import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary acuity plan snapshot calculation.
    protocol PrimaryAcuityPlanSnapshotStep {
        func describe() -> String
        func adjust(_ item: PrimaryAcuityPlanSnapshot, value: Double) -> Double
    }

    final class LabelPrimaryAcuityPlanSnapshotAdjuster: PrimaryAcuityPlanSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PrimaryAcuityPlanSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryAcuityPlanSnapshotAdjuster: PrimaryAcuityPlanSnapshotStep {
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

        func adjust(_ item: PrimaryAcuityPlanSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimaryAcuityPlanSnapshotAdjuster: PrimaryAcuityPlanSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryAcuityPlanSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryAcuityPlanSnapshotAdjuster: PrimaryAcuityPlanSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryAcuityPlanSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryAcuityPlanSnapshotAdjuster: PrimaryAcuityPlanSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryAcuityPlanSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the primary acuity plan snapshot steps in order and keeps a trace of each.
    final class PrimaryAcuityPlanSnapshotEngine {
        var steps: [any PrimaryAcuityPlanSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryAcuityPlanSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryAcuityPlanSnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PrimaryAcuityPlanSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryAcuityPlanSnapshotEngine(_ flags: Kit.Flags.Registry) -> PrimaryAcuityPlanSnapshotEngine {
        return PrimaryAcuityPlanSnapshotEngine(
            steps: [
                LabelPrimaryAcuityPlanSnapshotAdjuster(factors: ["north": 1.19]),
                FlaggedPrimaryAcuityPlanSnapshotAdjuster(
                    flags: flags,
                    flag: "primary-acuity-plan-snapshot-primary",
                    percent: -6.9
                ),
                TieredPrimaryAcuityPlanSnapshotAdjuster(
                    bounds: [2305.0, 4259.0, 7395.0, 9114.0],
                    rates: [0.82, 1.15, 1.09, 0.9]
                ),
                PercentPrimaryAcuityPlanSnapshotAdjuster(percent: -11.7),
                CapPrimaryAcuityPlanSnapshotAdjuster(cap: 23712.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 33812.2
        )
    }
}
