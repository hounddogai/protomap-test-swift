import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional outreach checkpoint calculation.
    protocol RegionalOutreachCheckpointStep {
        func describe() -> String
        func adjust(_ item: RegionalOutreachCheckpoint, value: Double) -> Double
    }

    final class CapRegionalOutreachCheckpointAdjuster: RegionalOutreachCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalOutreachCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalOutreachCheckpointAdjuster: RegionalOutreachCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOutreachCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalOutreachCheckpointAdjuster: RegionalOutreachCheckpointStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalOutreachCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentRegionalOutreachCheckpointAdjuster: RegionalOutreachCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RegionalOutreachCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalOutreachCheckpointAdjuster: RegionalOutreachCheckpointStep {
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

        func adjust(_ item: RegionalOutreachCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalOutreachCheckpointAdjuster: RegionalOutreachCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalOutreachCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional outreach checkpoint steps in order and keeps a trace of each.
    final class RegionalOutreachCheckpointEngine {
        var steps: [any RegionalOutreachCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOutreachCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalOutreachCheckpoint) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RegionalOutreachCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalOutreachCheckpointEngine(_ flags: Kit.Flags.Registry) -> RegionalOutreachCheckpointEngine {
        return RegionalOutreachCheckpointEngine(
            steps: [
                CapRegionalOutreachCheckpointAdjuster(cap: 17691.0),
                PercentRegionalOutreachCheckpointAdjuster(percent: -16.7),
                MinimumRegionalOutreachCheckpointAdjuster(minimum: 25.5),
                SegmentRegionalOutreachCheckpointAdjuster(factors: ["west": 1.0, "north": 1.36]),
                FlaggedRegionalOutreachCheckpointAdjuster(
                    flags: flags,
                    flag: "regional-outreach-checkpoint-capped",
                    percent: -3.7
                ),
                RoundingRegionalOutreachCheckpointAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 3640.0
        )
    }
}
