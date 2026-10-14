import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the tiered care protocol segment calculation.
    protocol TieredCareProtocolSegmentStep {
        func describe() -> String
        func adjust(_ item: TieredCareProtocolSegment, value: Double) -> Double
    }

    final class TieredCareProtocolSegmentRevisionOffsetAdjuster: TieredCareProtocolSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus revision times \(weight)"
        }

        func adjust(_ item: TieredCareProtocolSegment, value: Double) -> Double {
            return value + Double(item.revision) * weight
        }
    }

    final class FlaggedTieredCareProtocolSegmentAdjuster: TieredCareProtocolSegmentStep {
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

        func adjust(_ item: TieredCareProtocolSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapTieredCareProtocolSegmentAdjuster: TieredCareProtocolSegmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCareProtocolSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentTieredCareProtocolSegmentAdjuster: TieredCareProtocolSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredCareProtocolSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingTieredCareProtocolSegmentAdjuster: TieredCareProtocolSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredCareProtocolSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitTieredCareProtocolSegmentAdjuster: TieredCareProtocolSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: TieredCareProtocolSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered care protocol segment steps in order and keeps a trace of each.
    final class TieredCareProtocolSegmentEngine {
        var steps: [any TieredCareProtocolSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCareProtocolSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredCareProtocolSegment) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [TieredCareProtocolSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredCareProtocolSegmentEngine(_ flags: Kit.Flags.Registry) -> TieredCareProtocolSegmentEngine {
        return TieredCareProtocolSegmentEngine(
            steps: [
                TieredCareProtocolSegmentRevisionOffsetAdjuster(weight: 1.76),
                FlaggedTieredCareProtocolSegmentAdjuster(
                    flags: flags,
                    flag: "tiered-care-protocol-segment-primary",
                    percent: 1.4
                ),
                CapTieredCareProtocolSegmentAdjuster(cap: 33868.0),
                PercentTieredCareProtocolSegmentAdjuster(percent: -15.1),
                RoundingTieredCareProtocolSegmentAdjuster(step: 5.0),
                UnitTieredCareProtocolSegmentAdjuster(factors: ["south": 0.99, "north": 1.31]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 98994.8
        )
    }
}
