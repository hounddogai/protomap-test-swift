import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global specimen exception calculation.
    protocol GlobalSpecimenExceptionFactor {
        func describe() -> String
        func adjust(_ item: GlobalSpecimenException, value: Double) -> Double
    }

    final class RoundingGlobalSpecimenExceptionAdjuster: GlobalSpecimenExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalSpecimenException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalSpecimenExceptionAdjuster: GlobalSpecimenExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalSpecimenException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class GlobalSpecimenExceptionRetriesOffsetAdjuster: GlobalSpecimenExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: GlobalSpecimenException, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class FlaggedGlobalSpecimenExceptionAdjuster: GlobalSpecimenExceptionFactor {
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

        func adjust(_ item: GlobalSpecimenException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalSpecimenExceptionAdjuster: GlobalSpecimenExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalSpecimenException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global specimen exception steps in order and keeps a trace of each.
    final class GlobalSpecimenExceptionEngine {
        var steps: [any GlobalSpecimenExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSpecimenExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalSpecimenException) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalSpecimenExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [GlobalSpecimenException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalSpecimenExceptionEngine(_ flags: Kit.Flags.Registry) -> GlobalSpecimenExceptionEngine {
        return GlobalSpecimenExceptionEngine(
            steps: [
                RoundingGlobalSpecimenExceptionAdjuster(step: 0.25),
                MinimumGlobalSpecimenExceptionAdjuster(minimum: 23.8),
                GlobalSpecimenExceptionRetriesOffsetAdjuster(weight: 1.69),
                FlaggedGlobalSpecimenExceptionAdjuster(
                    flags: flags,
                    flag: "global-specimen-exception-lenient",
                    percent: 5.5
                ),
                TieredGlobalSpecimenExceptionAdjuster(bounds: [2999.0, 3206.0, 8507.0], rates: [0.88, 1.13, 0.92]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 81026.2
        )
    }
}
