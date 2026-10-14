import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary census segment calculation.
    protocol PrimaryCensusSegmentFactor {
        func describe() -> String
        func adjust(_ item: PrimaryCensusSegment, value: Double) -> Double
    }

    final class RoundingPrimaryCensusSegmentAdjuster: PrimaryCensusSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCensusSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPrimaryCensusSegmentAdjuster: PrimaryCensusSegmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryCensusSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPrimaryCensusSegmentAdjuster: PrimaryCensusSegmentFactor {
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

        func adjust(_ item: PrimaryCensusSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryCensusSegmentAdjuster: PrimaryCensusSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryCensusSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPrimaryCensusSegmentAdjuster: PrimaryCensusSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryCensusSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPrimaryCensusSegmentAdjuster: PrimaryCensusSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCensusSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary census segment steps in order and keeps a trace of each.
    final class PrimaryCensusSegmentEngine {
        var steps: [any PrimaryCensusSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCensusSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimaryCensusSegment) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryCensusSegmentFactor = steps[index]
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

        func evaluateAll(_ items: [PrimaryCensusSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimaryCensusSegmentEngine(_ flags: Kit.Flags.Registry) -> PrimaryCensusSegmentEngine {
        return PrimaryCensusSegmentEngine(
            steps: [
                RoundingPrimaryCensusSegmentAdjuster(step: 5.0),
                MinimumPrimaryCensusSegmentAdjuster(minimum: 27.6),
                FlaggedPrimaryCensusSegmentAdjuster(
                    flags: flags,
                    flag: "primary-census-segment-fallback",
                    percent: 7.2
                ),
                CapPrimaryCensusSegmentAdjuster(cap: 11536.0),
                TieredPrimaryCensusSegmentAdjuster(bounds: [4714.0, 7068.0, 9213.0], rates: [0.83, 0.92, 1.06]),
                PercentPrimaryCensusSegmentAdjuster(percent: -5.7),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 89162.9
        )
    }
}
