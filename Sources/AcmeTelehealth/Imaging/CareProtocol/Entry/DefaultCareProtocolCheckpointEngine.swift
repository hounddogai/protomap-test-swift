import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default care protocol checkpoint calculation.
    protocol DefaultCareProtocolCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultCareProtocolCheckpoint, value: Double) -> Double
    }

    final class FlaggedDefaultCareProtocolCheckpointAdjuster: DefaultCareProtocolCheckpointAdjuster {
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

        func adjust(_ item: DefaultCareProtocolCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultCareProtocolCheckpointScoreOffsetAdjuster: DefaultCareProtocolCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: DefaultCareProtocolCheckpoint, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentDefaultCareProtocolCheckpointAdjuster: DefaultCareProtocolCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCareProtocolCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDefaultCareProtocolCheckpointAdjuster: DefaultCareProtocolCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultCareProtocolCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelDefaultCareProtocolCheckpointAdjuster: DefaultCareProtocolCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultCareProtocolCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapDefaultCareProtocolCheckpointAdjuster: DefaultCareProtocolCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCareProtocolCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default care protocol checkpoint steps in order and keeps a trace of each.
    final class DefaultCareProtocolCheckpointEngine {
        var steps: [any DefaultCareProtocolCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCareProtocolCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCareProtocolCheckpoint) -> Double {
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

        func evaluateAll(_ items: [DefaultCareProtocolCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCareProtocolCheckpointEngine(_ flags: Kit.Flags.Registry) -> DefaultCareProtocolCheckpointEngine {
        return DefaultCareProtocolCheckpointEngine(
            steps: [
                FlaggedDefaultCareProtocolCheckpointAdjuster(
                    flags: flags,
                    flag: "default-care-protocol-checkpoint-seasonal",
                    percent: 4.9
                ),
                DefaultCareProtocolCheckpointScoreOffsetAdjuster(weight: 0.55),
                PercentDefaultCareProtocolCheckpointAdjuster(percent: -0.3),
                RoundingDefaultCareProtocolCheckpointAdjuster(step: 0.25),
                LabelDefaultCareProtocolCheckpointAdjuster(factors: ["east": 0.85, "west": 1.22]),
                CapDefaultCareProtocolCheckpointAdjuster(cap: 4578.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 66608.2
        )
    }
}
