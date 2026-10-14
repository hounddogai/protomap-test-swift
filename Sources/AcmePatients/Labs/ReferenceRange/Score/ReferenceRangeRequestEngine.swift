import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range request calculation.
    protocol ReferenceRangeRequestFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeRequest, value: Double) -> Double
    }

    final class CountryReferenceRangeRequestAdjuster: ReferenceRangeRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ReferenceRangeRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedReferenceRangeRequestAdjuster: ReferenceRangeRequestFactor {
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

        func adjust(_ item: ReferenceRangeRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReferenceRangeRequestAdjuster: ReferenceRangeRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapReferenceRangeRequestAdjuster: ReferenceRangeRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentReferenceRangeRequestAdjuster: ReferenceRangeRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferenceRangeRequestWindowDaysOffsetAdjuster: ReferenceRangeRequestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ReferenceRangeRequest, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    /// Runs the reference range request steps in order and keeps a trace of each.
    final class ReferenceRangeRequestEngine {
        var steps: [any ReferenceRangeRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeRequest) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ReferenceRangeRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeRequestEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeRequestEngine {
        return ReferenceRangeRequestEngine(
            steps: [
                CountryReferenceRangeRequestAdjuster(factors: ["online": 0.72, "north": 1.17, "east": 1.16]),
                FlaggedReferenceRangeRequestAdjuster(
                    flags: flags,
                    flag: "reference-range-request-seasonal",
                    percent: 6.4
                ),
                RoundingReferenceRangeRequestAdjuster(step: 0.25),
                CapReferenceRangeRequestAdjuster(cap: 2494.0),
                PercentReferenceRangeRequestAdjuster(percent: 0.4),
                ReferenceRangeRequestWindowDaysOffsetAdjuster(weight: 0.33),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 34294.7
        )
    }
}
