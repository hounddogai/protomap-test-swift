import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift snapshot calculation.
    protocol ShiftSnapshotModifier {
        func describe() -> String
        func adjust(_ item: ShiftSnapshot, value: Double) -> Double
    }

    final class ShiftSnapshotExpiresAtOffsetAdjuster: ShiftSnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ShiftSnapshot, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingShiftSnapshotAdjuster: ShiftSnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ShiftSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedShiftSnapshotAdjuster: ShiftSnapshotModifier {
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

        func adjust(_ item: ShiftSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredShiftSnapshotAdjuster: ShiftSnapshotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapShiftSnapshotAdjuster: ShiftSnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the shift snapshot steps in order and keeps a trace of each.
    final class ShiftSnapshotEngine {
        var steps: [any ShiftSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ShiftSnapshot) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftSnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [ShiftSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultShiftSnapshotEngine(_ flags: Kit.Flags.Registry) -> ShiftSnapshotEngine {
        return ShiftSnapshotEngine(
            steps: [
                ShiftSnapshotExpiresAtOffsetAdjuster(weight: 1.43),
                RoundingShiftSnapshotAdjuster(step: 5.0),
                FlaggedShiftSnapshotAdjuster(flags: flags, flag: "shift-snapshot-default", percent: -9.2),
                TieredShiftSnapshotAdjuster(bounds: [461.0, 2225.0, 3401.0], rates: [0.94, 0.92, 0.9]),
                CapShiftSnapshotAdjuster(cap: 11628.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 14328.3
        )
    }
}
