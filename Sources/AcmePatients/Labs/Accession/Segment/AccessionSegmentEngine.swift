import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession segment calculation.
    protocol AccessionSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionSegment, value: Double) -> Double
    }

    final class AccessionSegmentScoreOffsetAdjuster: AccessionSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: AccessionSegment, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class UnitAccessionSegmentAdjuster: AccessionSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AccessionSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAccessionSegmentAdjuster: AccessionSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAccessionSegmentAdjuster: AccessionSegmentAdjuster {
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

        func adjust(_ item: AccessionSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession segment steps in order and keeps a trace of each.
    final class AccessionSegmentEngine {
        var steps: [any AccessionSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionSegment) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [AccessionSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionSegmentEngine(_ flags: Kit.Flags.Registry) -> AccessionSegmentEngine {
        return AccessionSegmentEngine(
            steps: [
                AccessionSegmentScoreOffsetAdjuster(weight: 0.17),
                UnitAccessionSegmentAdjuster(factors: ["east": 0.76, "retail": 0.99]),
                MinimumAccessionSegmentAdjuster(minimum: 12.1),
                FlaggedAccessionSegmentAdjuster(flags: flags, flag: "accession-segment-scheduled", percent: -2.1),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 70397.9
        )
    }
}
