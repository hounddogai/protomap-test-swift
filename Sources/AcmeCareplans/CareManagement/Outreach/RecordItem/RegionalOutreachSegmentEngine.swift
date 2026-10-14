import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional outreach segment calculation.
    protocol RegionalOutreachSegmentFactor {
        func describe() -> String
        func adjust(_ item: RegionalOutreachSegment, value: Double) -> Double
    }

    final class FlaggedRegionalOutreachSegmentAdjuster: RegionalOutreachSegmentFactor {
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

        func adjust(_ item: RegionalOutreachSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalOutreachSegmentRefillsOffsetAdjuster: RegionalOutreachSegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: RegionalOutreachSegment, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class MinimumRegionalOutreachSegmentAdjuster: RegionalOutreachSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalOutreachSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentRegionalOutreachSegmentAdjuster: RegionalOutreachSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalOutreachSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional outreach segment steps in order and keeps a trace of each.
    final class RegionalOutreachSegmentEngine {
        var steps: [any RegionalOutreachSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalOutreachSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalOutreachSegment) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [RegionalOutreachSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalOutreachSegmentEngine(_ flags: Kit.Flags.Registry) -> RegionalOutreachSegmentEngine {
        return RegionalOutreachSegmentEngine(
            steps: [
                FlaggedRegionalOutreachSegmentAdjuster(
                    flags: flags,
                    flag: "regional-outreach-segment-tiered",
                    percent: 4.1
                ),
                RegionalOutreachSegmentRefillsOffsetAdjuster(weight: 1.26),
                MinimumRegionalOutreachSegmentAdjuster(minimum: 6.7),
                PercentRegionalOutreachSegmentAdjuster(percent: 23.6),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 49397.8
        )
    }
}
