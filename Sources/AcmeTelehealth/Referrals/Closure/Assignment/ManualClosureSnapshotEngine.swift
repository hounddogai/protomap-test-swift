import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual closure snapshot calculation.
    protocol ManualClosureSnapshotFactor {
        func describe() -> String
        func adjust(_ item: ManualClosureSnapshot, value: Double) -> Double
    }

    final class CapManualClosureSnapshotAdjuster: ManualClosureSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualClosureSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceManualClosureSnapshotAdjuster: ManualClosureSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ManualClosureSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualClosureSnapshotAdjuster: ManualClosureSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualClosureSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredManualClosureSnapshotAdjuster: ManualClosureSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualClosureSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualClosureSnapshotAdjuster: ManualClosureSnapshotFactor {
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

        func adjust(_ item: ManualClosureSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualClosureSnapshotWindowDaysOffsetAdjuster: ManualClosureSnapshotFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ManualClosureSnapshot, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the manual closure snapshot steps in order and keeps a trace of each.
    final class ManualClosureSnapshotEngine {
        var steps: [any ManualClosureSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualClosureSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualClosureSnapshot) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualClosureSnapshotFactor = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [ManualClosureSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualClosureSnapshotEngine(_ flags: Kit.Flags.Registry) -> ManualClosureSnapshotEngine {
        return ManualClosureSnapshotEngine(
            steps: [
                CapManualClosureSnapshotAdjuster(cap: 10669.0),
                SourceManualClosureSnapshotAdjuster(factors: ["east": 0.77, "online": 0.87, "west": 0.92]),
                RoundingManualClosureSnapshotAdjuster(step: 0.1),
                TieredManualClosureSnapshotAdjuster(
                    bounds: [1444.0, 1800.0, 4669.0, 8482.0],
                    rates: [1.08, 0.96, 0.87, 0.94]
                ),
                FlaggedManualClosureSnapshotAdjuster(
                    flags: flags,
                    flag: "manual-closure-snapshot-strict",
                    percent: -9.8
                ),
                ManualClosureSnapshotWindowDaysOffsetAdjuster(weight: 1.88),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 18327.8
        )
    }
}
