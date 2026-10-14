import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending result segment calculation.
    protocol PendingResultSegmentFactor {
        func describe() -> String
        func adjust(_ item: PendingResultSegment, value: Double) -> Double
    }

    final class RoundingPendingResultSegmentAdjuster: PendingResultSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingResultSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PendingResultSegmentEndsAtOffsetAdjuster: PendingResultSegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: PendingResultSegment, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class FlaggedPendingResultSegmentAdjuster: PendingResultSegmentFactor {
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

        func adjust(_ item: PendingResultSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumPendingResultSegmentAdjuster: PendingResultSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingResultSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending result segment steps in order and keeps a trace of each.
    final class PendingResultSegmentEngine {
        var steps: [any PendingResultSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingResultSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingResultSegment) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PendingResultSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingResultSegmentEngine(_ flags: Kit.Flags.Registry) -> PendingResultSegmentEngine {
        return PendingResultSegmentEngine(
            steps: [
                RoundingPendingResultSegmentAdjuster(step: 0.5),
                PendingResultSegmentEndsAtOffsetAdjuster(weight: 1.53),
                FlaggedPendingResultSegmentAdjuster(
                    flags: flags,
                    flag: "pending-result-segment-batched",
                    percent: 1.9
                ),
                MinimumPendingResultSegmentAdjuster(minimum: 7.4),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 32899.9
        )
    }
}
