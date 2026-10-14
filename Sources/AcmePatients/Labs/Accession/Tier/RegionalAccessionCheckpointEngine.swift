import AcmePlatform
import Foundation

extension Labs {
    /// One step of the regional accession checkpoint calculation.
    protocol RegionalAccessionCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalAccessionCheckpoint, value: Double) -> Double
    }

    final class FlaggedRegionalAccessionCheckpointAdjuster: RegionalAccessionCheckpointAdjuster {
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

        func adjust(_ item: RegionalAccessionCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalAccessionCheckpointAdjuster: RegionalAccessionCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalAccessionCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameRegionalAccessionCheckpointAdjuster: RegionalAccessionCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalAccessionCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalAccessionCheckpointAdjuster: RegionalAccessionCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalAccessionCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the regional accession checkpoint steps in order and keeps a trace of each.
    final class RegionalAccessionCheckpointEngine {
        var steps: [any RegionalAccessionCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAccessionCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalAccessionCheckpoint) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalAccessionCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalAccessionCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalAccessionCheckpointEngine(_ flags: Kit.Flags.Registry) -> RegionalAccessionCheckpointEngine {
        return RegionalAccessionCheckpointEngine(
            steps: [
                FlaggedRegionalAccessionCheckpointAdjuster(
                    flags: flags,
                    flag: "regional-accession-checkpoint-global",
                    percent: -2.1
                ),
                MinimumRegionalAccessionCheckpointAdjuster(minimum: 18.2),
                NameRegionalAccessionCheckpointAdjuster(factors: ["south": 0.9, "central": 1.05]),
                RoundingRegionalAccessionCheckpointAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 8737.4
        )
    }
}
