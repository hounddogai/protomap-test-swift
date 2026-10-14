import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped care protocol checkpoint calculation.
    protocol CappedCareProtocolCheckpointStep {
        func describe() -> String
        func adjust(_ item: CappedCareProtocolCheckpoint, value: Double) -> Double
    }

    final class CappedCareProtocolCheckpointRetriesOffsetAdjuster: CappedCareProtocolCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: CappedCareProtocolCheckpoint, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class FlaggedCappedCareProtocolCheckpointAdjuster: CappedCareProtocolCheckpointStep {
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

        func adjust(_ item: CappedCareProtocolCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryCappedCareProtocolCheckpointAdjuster: CappedCareProtocolCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CappedCareProtocolCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the capped care protocol checkpoint steps in order and keeps a trace of each.
    final class CappedCareProtocolCheckpointEngine {
        var steps: [any CappedCareProtocolCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareProtocolCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedCareProtocolCheckpoint) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedCareProtocolCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [CappedCareProtocolCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedCareProtocolCheckpointEngine(_ flags: Kit.Flags.Registry) -> CappedCareProtocolCheckpointEngine {
        return CappedCareProtocolCheckpointEngine(
            steps: [
                CappedCareProtocolCheckpointRetriesOffsetAdjuster(weight: 1.73),
                FlaggedCappedCareProtocolCheckpointAdjuster(
                    flags: flags,
                    flag: "capped-care-protocol-checkpoint-primary",
                    percent: -2.9
                ),
                CountryCappedCareProtocolCheckpointAdjuster(factors: ["west": 0.88, "central": 1.34]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 41720.8
        )
    }
}
