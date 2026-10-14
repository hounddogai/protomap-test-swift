import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered denial checkpoint calculation.
    protocol VarianceTieredDenialCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: TieredDenialCheckpoint, value: Double) -> Double
    }

    final class TieredDenialCheckpointVersionOffsetAdjuster: VarianceTieredDenialCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: TieredDenialCheckpoint, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class FlaggedTieredDenialCheckpointAdjuster: VarianceTieredDenialCheckpointAdjuster {
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

        func adjust(_ item: TieredDenialCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredDenialCheckpointAdjuster: VarianceTieredDenialCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredDenialCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered denial checkpoint steps in order and keeps a trace of each.
    final class TieredDenialCheckpointEngine {
        var steps: [any VarianceTieredDenialCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any VarianceTieredDenialCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredDenialCheckpoint) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any VarianceTieredDenialCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredDenialCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredDenialCheckpointEngine(_ flags: Kit.Flags.Registry) -> TieredDenialCheckpointEngine {
        return TieredDenialCheckpointEngine(
            steps: [
                TieredDenialCheckpointVersionOffsetAdjuster(weight: 1.79),
                FlaggedTieredDenialCheckpointAdjuster(
                    flags: flags,
                    flag: "tiered-denial-checkpoint-lenient",
                    percent: 7.1
                ),
                RoundingTieredDenialCheckpointAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 26128.4
        )
    }
}
