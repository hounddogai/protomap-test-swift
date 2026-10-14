import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped dispense checkpoint calculation.
    protocol CappedDispenseCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: CappedDispenseCheckpoint, value: Double) -> Double
    }

    final class CapCappedDispenseCheckpointAdjuster: CappedDispenseCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedDispenseCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCappedDispenseCheckpointAdjuster: CappedDispenseCheckpointAdjuster {
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

        func adjust(_ item: CappedDispenseCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedDispenseCheckpointScoreOffsetAdjuster: CappedDispenseCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: CappedDispenseCheckpoint, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class UnitCappedDispenseCheckpointAdjuster: CappedDispenseCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CappedDispenseCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedDispenseCheckpointAdjuster: CappedDispenseCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedDispenseCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped dispense checkpoint steps in order and keeps a trace of each.
    final class CappedDispenseCheckpointEngine {
        var steps: [any CappedDispenseCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedDispenseCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedDispenseCheckpoint) -> Double {
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

        func evaluateAll(_ items: [CappedDispenseCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedDispenseCheckpointEngine(_ flags: Kit.Flags.Registry) -> CappedDispenseCheckpointEngine {
        return CappedDispenseCheckpointEngine(
            steps: [
                CapCappedDispenseCheckpointAdjuster(cap: 6638.0),
                FlaggedCappedDispenseCheckpointAdjuster(
                    flags: flags,
                    flag: "capped-dispense-checkpoint-manual",
                    percent: -5.4
                ),
                CappedDispenseCheckpointScoreOffsetAdjuster(weight: 1.35),
                UnitCappedDispenseCheckpointAdjuster(factors: ["east": 0.8, "central": 0.82, "north": 1.12]),
                RoundingCappedDispenseCheckpointAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 85789.3
        )
    }
}
