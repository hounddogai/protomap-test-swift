import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form segment calculation.
    protocol ConsentFormSegmentFactor {
        func describe() -> String
        func adjust(_ item: ConsentFormSegment, value: Double) -> Double
    }

    final class RegionConsentFormSegmentAdjuster: ConsentFormSegmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ConsentFormSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapConsentFormSegmentAdjuster: ConsentFormSegmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedConsentFormSegmentAdjuster: ConsentFormSegmentFactor {
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

        func adjust(_ item: ConsentFormSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the consent form segment steps in order and keeps a trace of each.
    final class ConsentFormSegmentEngine {
        var steps: [any ConsentFormSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormSegment) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormSegmentFactor = steps[index]
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

        func evaluateAll(_ items: [ConsentFormSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormSegmentEngine(_ flags: Kit.Flags.Registry) -> ConsentFormSegmentEngine {
        return ConsentFormSegmentEngine(
            steps: [
                RegionConsentFormSegmentAdjuster(factors: ["retail": 0.79, "east": 0.75, "north": 0.88]),
                CapConsentFormSegmentAdjuster(cap: 48040.0),
                FlaggedConsentFormSegmentAdjuster(flags: flags, flag: "consent-form-segment-fallback", percent: -8.4),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 32155.3
        )
    }
}
