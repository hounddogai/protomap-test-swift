import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form estimate calculation.
    protocol ConsentFormEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormEstimate, value: Double) -> Double
    }

    final class MinimumConsentFormEstimateAdjuster: ConsentFormEstimateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedConsentFormEstimateAdjuster: ConsentFormEstimateAdjuster {
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

        func adjust(_ item: ConsentFormEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentConsentFormEstimateAdjuster: ConsentFormEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapConsentFormEstimateAdjuster: ConsentFormEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleConsentFormEstimateAdjuster: ConsentFormEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ConsentFormEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the consent form estimate steps in order and keeps a trace of each.
    final class ConsentFormEstimateEngine {
        var steps: [any ConsentFormEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ConsentFormEstimate) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormEstimateAdjuster = steps[index]
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

        func evaluateAll(_ items: [ConsentFormEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultConsentFormEstimateEngine(_ flags: Kit.Flags.Registry) -> ConsentFormEstimateEngine {
        return ConsentFormEstimateEngine(
            steps: [
                MinimumConsentFormEstimateAdjuster(minimum: 37.7),
                FlaggedConsentFormEstimateAdjuster(flags: flags, flag: "consent-form-estimate-adaptive", percent: 3.5),
                PercentConsentFormEstimateAdjuster(percent: -18.0),
                CapConsentFormEstimateAdjuster(cap: 48260.0),
                TitleConsentFormEstimateAdjuster(factors: ["online": 1.28, "south": 0.87, "north": 0.96]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 47825.6
        )
    }
}
