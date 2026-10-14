import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program snapshot calculation.
    protocol ProgramSnapshotFactor {
        func describe() -> String
        func adjust(_ item: ProgramSnapshot, value: Double) -> Double
    }

    final class FlaggedProgramSnapshotAdjuster: ProgramSnapshotFactor {
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

        func adjust(_ item: ProgramSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredProgramSnapshotAdjuster: ProgramSnapshotFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentProgramSnapshotAdjuster: ProgramSnapshotFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProgramSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapProgramSnapshotAdjuster: ProgramSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProgramSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the program snapshot steps in order and keeps a trace of each.
    final class ProgramSnapshotEngine {
        var steps: [any ProgramSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProgramSnapshot) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ProgramSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [ProgramSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProgramSnapshotEngine(_ flags: Kit.Flags.Registry) -> ProgramSnapshotEngine {
        return ProgramSnapshotEngine(
            steps: [
                FlaggedProgramSnapshotAdjuster(flags: flags, flag: "program-snapshot-pending", percent: 3.5),
                TieredProgramSnapshotAdjuster(bounds: [3616.0, 4113.0], rates: [0.91, 0.91]),
                PercentProgramSnapshotAdjuster(percent: 18.8),
                CapProgramSnapshotAdjuster(cap: 46040.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 97854.1
        )
    }
}
