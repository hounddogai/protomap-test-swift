import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score checkpoint calculation.
    protocol RiskScoreCheckpointFactor {
        func describe() -> String
        func adjust(_ item: RiskScoreCheckpoint, value: Double) -> Double
    }

    final class LabelRiskScoreCheckpointAdjuster: RiskScoreCheckpointFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RiskScoreCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRiskScoreCheckpointAdjuster: RiskScoreCheckpointFactor {
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

        func adjust(_ item: RiskScoreCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRiskScoreCheckpointAdjuster: RiskScoreCheckpointFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RiskScoreCheckpointCeilingOffsetAdjuster: RiskScoreCheckpointFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: RiskScoreCheckpoint, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class CapRiskScoreCheckpointAdjuster: RiskScoreCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RiskScoreCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the risk score checkpoint steps in order and keeps a trace of each.
    final class RiskScoreCheckpointEngine {
        var steps: [any RiskScoreCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RiskScoreCheckpoint) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [RiskScoreCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRiskScoreCheckpointEngine(_ flags: Kit.Flags.Registry) -> RiskScoreCheckpointEngine {
        return RiskScoreCheckpointEngine(
            steps: [
                LabelRiskScoreCheckpointAdjuster(factors: ["retail": 0.8, "south": 1.23]),
                FlaggedRiskScoreCheckpointAdjuster(flags: flags, flag: "risk-score-checkpoint-weighted", percent: 1.8),
                TieredRiskScoreCheckpointAdjuster(bounds: [263.0, 2928.0, 8469.0], rates: [0.97, 1.17, 1.05]),
                RiskScoreCheckpointCeilingOffsetAdjuster(weight: 1.31),
                CapRiskScoreCheckpointAdjuster(cap: 5587.0),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 63260.1
        )
    }
}
