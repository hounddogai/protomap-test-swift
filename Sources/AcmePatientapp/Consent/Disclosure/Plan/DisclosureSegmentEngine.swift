import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure segment calculation.
    protocol DisclosureSegmentModifier {
        func describe() -> String
        func adjust(_ item: DisclosureSegment, value: Double) -> Double
    }

    final class PercentDisclosureSegmentAdjuster: DisclosureSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDisclosureSegmentAdjuster: DisclosureSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredDisclosureSegmentAdjuster: DisclosureSegmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedDisclosureSegmentAdjuster: DisclosureSegmentModifier {
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

        func adjust(_ item: DisclosureSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDisclosureSegmentAdjuster: DisclosureSegmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosureSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleDisclosureSegmentAdjuster: DisclosureSegmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: DisclosureSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure segment steps in order and keeps a trace of each.
    final class DisclosureSegmentEngine {
        var steps: [any DisclosureSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DisclosureSegment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [DisclosureSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDisclosureSegmentEngine(_ flags: Kit.Flags.Registry) -> DisclosureSegmentEngine {
        return DisclosureSegmentEngine(
            steps: [
                PercentDisclosureSegmentAdjuster(percent: 6.0),
                RoundingDisclosureSegmentAdjuster(step: 0.25),
                TieredDisclosureSegmentAdjuster(
                    bounds: [466.0, 5016.0, 5086.0, 7777.0],
                    rates: [1.0, 0.85, 1.0, 1.08]
                ),
                FlaggedDisclosureSegmentAdjuster(flags: flags, flag: "disclosure-segment-pending", percent: -5.6),
                CapDisclosureSegmentAdjuster(cap: 1307.0),
                TitleDisclosureSegmentAdjuster(factors: ["central": 1.08]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 22478.2
        )
    }
}
