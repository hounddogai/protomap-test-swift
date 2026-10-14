import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the strict read snapshot calculation.
    protocol StrictReadSnapshotModifier {
        func describe() -> String
        func adjust(_ item: StrictReadSnapshot, value: Double) -> Double
    }

    final class CapStrictReadSnapshotAdjuster: StrictReadSnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictReadSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictReadSnapshotPriorityOffsetAdjuster: StrictReadSnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: StrictReadSnapshot, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class FlaggedStrictReadSnapshotAdjuster: StrictReadSnapshotModifier {
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

        func adjust(_ item: StrictReadSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictReadSnapshotAdjuster: StrictReadSnapshotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictReadSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictReadSnapshotAdjuster: StrictReadSnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictReadSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the strict read snapshot steps in order and keeps a trace of each.
    final class StrictReadSnapshotEngine {
        var steps: [any StrictReadSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReadSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictReadSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictReadSnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [StrictReadSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictReadSnapshotEngine(_ flags: Kit.Flags.Registry) -> StrictReadSnapshotEngine {
        return StrictReadSnapshotEngine(
            steps: [
                CapStrictReadSnapshotAdjuster(cap: 30021.0),
                StrictReadSnapshotPriorityOffsetAdjuster(weight: 1.25),
                FlaggedStrictReadSnapshotAdjuster(flags: flags, flag: "strict-read-snapshot-default", percent: -4.6),
                TieredStrictReadSnapshotAdjuster(bounds: [4646.0, 4798.0, 5419.0], rates: [1.08, 0.99, 0.88]),
                RoundingStrictReadSnapshotAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 94644.9
        )
    }
}
