import AcmePlatform
import Foundation

extension Labs {
    /// One step of the lenient reference range draft calculation.
    protocol LenientReferenceRangeDraftFactor {
        func describe() -> String
        func adjust(_ item: LenientReferenceRangeDraft, value: Double) -> Double
    }

    final class FlaggedLenientReferenceRangeDraftAdjuster: LenientReferenceRangeDraftFactor {
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

        func adjust(_ item: LenientReferenceRangeDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientReferenceRangeDraftAdjuster: LenientReferenceRangeDraftFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientReferenceRangeDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientReferenceRangeDraftAdjuster: LenientReferenceRangeDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientReferenceRangeDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the lenient reference range draft steps in order and keeps a trace of each.
    final class LenientReferenceRangeDraftEngine {
        var steps: [any LenientReferenceRangeDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientReferenceRangeDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientReferenceRangeDraft) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientReferenceRangeDraftFactor = steps[index]
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

        func evaluateAll(_ items: [LenientReferenceRangeDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientReferenceRangeDraftEngine(_ flags: Kit.Flags.Registry) -> LenientReferenceRangeDraftEngine {
        return LenientReferenceRangeDraftEngine(
            steps: [
                FlaggedLenientReferenceRangeDraftAdjuster(
                    flags: flags,
                    flag: "lenient-reference-range-draft-fallback",
                    percent: -7.1
                ),
                RoundingLenientReferenceRangeDraftAdjuster(step: 5.0),
                TieredLenientReferenceRangeDraftAdjuster(bounds: [1648.0, 1667.0, 5437.0], rates: [0.91, 0.93, 0.83]),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 13203.1
        )
    }
}
