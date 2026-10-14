import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary program checkpoint calculation.
    protocol PrimaryProgramCheckpointFactor {
        func describe() -> String
        func adjust(_ item: PrimaryProgramCheckpoint, value: Double) -> Double
    }

    final class CapPrimaryProgramCheckpointAdjuster: PrimaryProgramCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryProgramCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourcePrimaryProgramCheckpointAdjuster: PrimaryProgramCheckpointFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: PrimaryProgramCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryProgramCheckpointAdjuster: PrimaryProgramCheckpointFactor {
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

        func adjust(_ item: PrimaryProgramCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryProgramCheckpointAdjuster: PrimaryProgramCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryProgramCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPrimaryProgramCheckpointAdjuster: PrimaryProgramCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryProgramCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary program checkpoint steps in order and keeps a trace of each.
    final class PrimaryProgramCheckpointEngine {
        var steps: [any PrimaryProgramCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryProgramCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryProgramCheckpoint) -> Double {
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

        func evaluateAll(_ items: [PrimaryProgramCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryProgramCheckpointEngine(_ flags: Kit.Flags.Registry) -> PrimaryProgramCheckpointEngine {
        return PrimaryProgramCheckpointEngine(
            steps: [
                CapPrimaryProgramCheckpointAdjuster(cap: 17126.0),
                SourcePrimaryProgramCheckpointAdjuster(factors: ["north": 0.71]),
                FlaggedPrimaryProgramCheckpointAdjuster(
                    flags: flags,
                    flag: "primary-program-checkpoint-lenient",
                    percent: 4.4
                ),
                RoundingPrimaryProgramCheckpointAdjuster(step: 0.1),
                PercentPrimaryProgramCheckpointAdjuster(percent: 11.1),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 38266.0
        )
    }
}
