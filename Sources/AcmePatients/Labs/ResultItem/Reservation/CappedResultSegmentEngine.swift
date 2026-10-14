import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped result segment calculation.
    protocol CappedResultSegmentFactor {
        func describe() -> String
        func adjust(_ item: CappedResultSegment, value: Double) -> Double
    }

    final class PercentCappedResultSegmentAdjuster: CappedResultSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedResultSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityCappedResultSegmentAdjuster: CappedResultSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CappedResultSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CappedResultSegmentEndsAtOffsetAdjuster: CappedResultSegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: CappedResultSegment, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumCappedResultSegmentAdjuster: CappedResultSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedResultSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCappedResultSegmentAdjuster: CappedResultSegmentFactor {
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

        func adjust(_ item: CappedResultSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedResultSegmentAdjuster: CappedResultSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedResultSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the capped result segment steps in order and keeps a trace of each.
    final class CappedResultSegmentEngine {
        var steps: [any CappedResultSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedResultSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CappedResultSegment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedResultSegmentFactor = steps[index]
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

        func evaluateAll(_ items: [CappedResultSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCappedResultSegmentEngine(_ flags: Kit.Flags.Registry) -> CappedResultSegmentEngine {
        return CappedResultSegmentEngine(
            steps: [
                PercentCappedResultSegmentAdjuster(percent: 1.4),
                FacilityCappedResultSegmentAdjuster(factors: ["east": 1.26]),
                CappedResultSegmentEndsAtOffsetAdjuster(weight: 1.18),
                MinimumCappedResultSegmentAdjuster(minimum: 16.0),
                FlaggedCappedResultSegmentAdjuster(flags: flags, flag: "capped-result-segment-fallback", percent: 0.1),
                CapCappedResultSegmentAdjuster(cap: 3905.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 21987.0
        )
    }
}
