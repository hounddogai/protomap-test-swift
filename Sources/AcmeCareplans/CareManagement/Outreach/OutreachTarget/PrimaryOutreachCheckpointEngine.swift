import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the primary outreach checkpoint calculation.
    protocol PrimaryOutreachCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryOutreachCheckpoint, value: Double) -> Double
    }

    final class PercentPrimaryOutreachCheckpointAdjuster: PrimaryOutreachCheckpointAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOutreachCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryOutreachCheckpointAdjuster: PrimaryOutreachCheckpointAdjuster {
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

        func adjust(_ item: PrimaryOutreachCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryOutreachCheckpointAdjuster: PrimaryOutreachCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryOutreachCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ChannelPrimaryOutreachCheckpointAdjuster: PrimaryOutreachCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: PrimaryOutreachCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredPrimaryOutreachCheckpointAdjuster: PrimaryOutreachCheckpointAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOutreachCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary outreach checkpoint steps in order and keeps a trace of each.
    final class PrimaryOutreachCheckpointEngine {
        var steps: [any PrimaryOutreachCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOutreachCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryOutreachCheckpoint) -> Double {
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

        func evaluateAll(_ items: [PrimaryOutreachCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryOutreachCheckpointEngine(_ flags: Kit.Flags.Registry) -> PrimaryOutreachCheckpointEngine {
        return PrimaryOutreachCheckpointEngine(
            steps: [
                PercentPrimaryOutreachCheckpointAdjuster(percent: -20.5),
                FlaggedPrimaryOutreachCheckpointAdjuster(
                    flags: flags,
                    flag: "primary-outreach-checkpoint-adaptive",
                    percent: 1.5
                ),
                RoundingPrimaryOutreachCheckpointAdjuster(step: 0.25),
                ChannelPrimaryOutreachCheckpointAdjuster(factors: ["south": 1.28]),
                TieredPrimaryOutreachCheckpointAdjuster(bounds: [5052.0, 7726.0, 9498.0], rates: [1.14, 1.11, 1.09]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 33851.5
        )
    }
}
