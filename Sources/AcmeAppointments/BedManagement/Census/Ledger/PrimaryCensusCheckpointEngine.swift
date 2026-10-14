import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary census checkpoint calculation.
    protocol PrimaryCensusCheckpointStep {
        func describe() -> String
        func adjust(_ item: PrimaryCensusCheckpoint, value: Double) -> Double
    }

    final class CapPrimaryCensusCheckpointAdjuster: PrimaryCensusCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCensusCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPrimaryCensusCheckpointAdjuster: PrimaryCensusCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryCensusCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentPrimaryCensusCheckpointAdjuster: PrimaryCensusCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: PrimaryCensusCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPrimaryCensusCheckpointAdjuster: PrimaryCensusCheckpointStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCensusCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryCensusCheckpointAdjuster: PrimaryCensusCheckpointStep {
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

        func adjust(_ item: PrimaryCensusCheckpoint, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryCensusCheckpointBatchSizeOffsetAdjuster: PrimaryCensusCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: PrimaryCensusCheckpoint, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the primary census checkpoint steps in order and keeps a trace of each.
    final class PrimaryCensusCheckpointEngine {
        var steps: [any PrimaryCensusCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCensusCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryCensusCheckpoint) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryCensusCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [PrimaryCensusCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryCensusCheckpointEngine(_ flags: Kit.Flags.Registry) -> PrimaryCensusCheckpointEngine {
        return PrimaryCensusCheckpointEngine(
            steps: [
                CapPrimaryCensusCheckpointAdjuster(cap: 24230.0),
                TieredPrimaryCensusCheckpointAdjuster(bounds: [2980.0, 3797.0, 8231.0], rates: [1.01, 1.17, 1.13]),
                SegmentPrimaryCensusCheckpointAdjuster(factors: ["central": 1.39, "retail": 1.04]),
                MinimumPrimaryCensusCheckpointAdjuster(minimum: 30.9),
                FlaggedPrimaryCensusCheckpointAdjuster(
                    flags: flags,
                    flag: "primary-census-checkpoint-primary",
                    percent: 6.9
                ),
                PrimaryCensusCheckpointBatchSizeOffsetAdjuster(weight: 1.06),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 84522.0
        )
    }
}
