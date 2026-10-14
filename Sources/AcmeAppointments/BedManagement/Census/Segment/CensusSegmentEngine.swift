import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census segment calculation.
    protocol CensusSegmentModifier {
        func describe() -> String
        func adjust(_ item: CensusSegment, value: Double) -> Double
    }

    final class WardCensusSegmentAdjuster: CensusSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CensusSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCensusSegmentAdjuster: CensusSegmentModifier {
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

        func adjust(_ item: CensusSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentCensusSegmentAdjuster: CensusSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census segment steps in order and keeps a trace of each.
    final class CensusSegmentEngine {
        var steps: [any CensusSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CensusSegment) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [CensusSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCensusSegmentEngine(_ flags: Kit.Flags.Registry) -> CensusSegmentEngine {
        return CensusSegmentEngine(
            steps: [
                WardCensusSegmentAdjuster(factors: ["central": 1.36, "west": 1.01]),
                FlaggedCensusSegmentAdjuster(flags: flags, flag: "census-segment-lenient", percent: -0.1),
                PercentCensusSegmentAdjuster(percent: 10.8),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 16935.7
        )
    }
}
