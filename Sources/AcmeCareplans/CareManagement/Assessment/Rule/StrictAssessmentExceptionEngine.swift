import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the strict assessment exception calculation.
    protocol StrictAssessmentExceptionFactor {
        func describe() -> String
        func adjust(_ item: StrictAssessmentException, value: Double) -> Double
    }

    final class TieredStrictAssessmentExceptionAdjuster: StrictAssessmentExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictAssessmentException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapStrictAssessmentExceptionAdjuster: StrictAssessmentExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictAssessmentException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelStrictAssessmentExceptionAdjuster: StrictAssessmentExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StrictAssessmentException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingStrictAssessmentExceptionAdjuster: StrictAssessmentExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictAssessmentException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictAssessmentExceptionAdjuster: StrictAssessmentExceptionFactor {
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

        func adjust(_ item: StrictAssessmentException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict assessment exception steps in order and keeps a trace of each.
    final class StrictAssessmentExceptionEngine {
        var steps: [any StrictAssessmentExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAssessmentExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictAssessmentException) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictAssessmentExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [StrictAssessmentException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictAssessmentExceptionEngine(_ flags: Kit.Flags.Registry) -> StrictAssessmentExceptionEngine {
        return StrictAssessmentExceptionEngine(
            steps: [
                TieredStrictAssessmentExceptionAdjuster(bounds: [6290.0, 6986.0], rates: [1.16, 1.17]),
                CapStrictAssessmentExceptionAdjuster(cap: 24564.0),
                ChannelStrictAssessmentExceptionAdjuster(factors: ["online": 0.75, "east": 0.85]),
                RoundingStrictAssessmentExceptionAdjuster(step: 5.0),
                FlaggedStrictAssessmentExceptionAdjuster(
                    flags: flags,
                    flag: "strict-assessment-exception-seasonal",
                    percent: -8.2
                ),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 11045.2
        )
    }
}
