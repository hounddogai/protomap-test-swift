import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient accession checkpoint calculation.
    protocol LenientAccessionCheckpointModifier {
        func describe() -> String
        func adjust(_ item: LenientAccessionCheckpoint, value: Double) -> Double
    }

    final class FlaggedLenientAccessionCheckpointAdjuster: LenientAccessionCheckpointModifier {
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

        func adjust(_ item: LenientAccessionCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientAccessionCheckpointAdjuster: LenientAccessionCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientAccessionCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelLenientAccessionCheckpointAdjuster: LenientAccessionCheckpointModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: LenientAccessionCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient accession checkpoint steps in order and keeps a trace of each.
    final class LenientAccessionCheckpointEngine {
        var steps: [any LenientAccessionCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAccessionCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientAccessionCheckpoint) -> Double {
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

        func evaluateAll(_ items: [LenientAccessionCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientAccessionCheckpointEngine(_ flags: Kit.Flags.Registry) -> LenientAccessionCheckpointEngine {
        return LenientAccessionCheckpointEngine(
            steps: [
                FlaggedLenientAccessionCheckpointAdjuster(
                    flags: flags,
                    flag: "lenient-accession-checkpoint-rolling",
                    percent: -5.2
                ),
                PercentLenientAccessionCheckpointAdjuster(percent: 17.4),
                ChannelLenientAccessionCheckpointAdjuster(factors: ["central": 1.18]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 78347.6
        )
    }
}
