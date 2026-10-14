import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan snapshot calculation.
    protocol AcuityPlanSnapshotStep {
        func describe() -> String
        func adjust(_ item: AcuityPlanSnapshot, value: Double) -> Double
    }

    final class MinimumAcuityPlanSnapshotAdjuster: AcuityPlanSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AcuityPlanSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAcuityPlanSnapshotAdjuster: AcuityPlanSnapshotStep {
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

        func adjust(_ item: AcuityPlanSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAcuityPlanSnapshotAdjuster: AcuityPlanSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class AcuityPlanSnapshotDosageMgOffsetAdjuster: AcuityPlanSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: AcuityPlanSnapshot, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the acuity plan snapshot steps in order and keeps a trace of each.
    final class AcuityPlanSnapshotEngine {
        var steps: [any AcuityPlanSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanSnapshot) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [AcuityPlanSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanSnapshotEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanSnapshotEngine {
        return AcuityPlanSnapshotEngine(
            steps: [
                MinimumAcuityPlanSnapshotAdjuster(minimum: 23.6),
                FlaggedAcuityPlanSnapshotAdjuster(flags: flags, flag: "acuity-plan-snapshot-regional", percent: 4.5),
                TieredAcuityPlanSnapshotAdjuster(
                    bounds: [1859.0, 2003.0, 2256.0, 4144.0],
                    rates: [1.14, 1.13, 0.81, 0.95]
                ),
                AcuityPlanSnapshotDosageMgOffsetAdjuster(weight: 1.64),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 44318.7
        )
    }
}
