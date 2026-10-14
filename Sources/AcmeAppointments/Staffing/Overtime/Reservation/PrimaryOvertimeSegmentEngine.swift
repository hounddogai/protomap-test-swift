import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the primary overtime segment calculation.
    protocol PrimaryOvertimeSegmentModifier {
        func describe() -> String
        func adjust(_ item: PrimaryOvertimeSegment, value: Double) -> Double
    }

    final class PrimaryOvertimeSegmentQuantityOffsetAdjuster: PrimaryOvertimeSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: PrimaryOvertimeSegment, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentPrimaryOvertimeSegmentAdjuster: PrimaryOvertimeSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryOvertimeSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedPrimaryOvertimeSegmentAdjuster: PrimaryOvertimeSegmentModifier {
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

        func adjust(_ item: PrimaryOvertimeSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPrimaryOvertimeSegmentAdjuster: PrimaryOvertimeSegmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryOvertimeSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPrimaryOvertimeSegmentAdjuster: PrimaryOvertimeSegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryOvertimeSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NamePrimaryOvertimeSegmentAdjuster: PrimaryOvertimeSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: PrimaryOvertimeSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the primary overtime segment steps in order and keeps a trace of each.
    final class PrimaryOvertimeSegmentEngine {
        var steps: [any PrimaryOvertimeSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryOvertimeSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryOvertimeSegment) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryOvertimeSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryOvertimeSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryOvertimeSegmentEngine(_ flags: Kit.Flags.Registry) -> PrimaryOvertimeSegmentEngine {
        return PrimaryOvertimeSegmentEngine(
            steps: [
                PrimaryOvertimeSegmentQuantityOffsetAdjuster(weight: 1.99),
                PercentPrimaryOvertimeSegmentAdjuster(percent: -11.9),
                FlaggedPrimaryOvertimeSegmentAdjuster(
                    flags: flags,
                    flag: "primary-overtime-segment-legacy",
                    percent: 2.4
                ),
                CapPrimaryOvertimeSegmentAdjuster(cap: 2982.0),
                TieredPrimaryOvertimeSegmentAdjuster(bounds: [1304.0, 2178.0, 9317.0], rates: [0.85, 0.81, 1.07]),
                NamePrimaryOvertimeSegmentAdjuster(factors: ["retail": 0.92, "east": 1.35, "north": 0.74]),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 52335.9
        )
    }
}
