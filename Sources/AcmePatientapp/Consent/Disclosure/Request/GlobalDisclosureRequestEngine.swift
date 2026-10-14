import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global disclosure request calculation.
    protocol GlobalDisclosureRequestStep {
        func describe() -> String
        func adjust(_ item: GlobalDisclosureRequest, value: Double) -> Double
    }

    final class FlaggedGlobalDisclosureRequestAdjuster: GlobalDisclosureRequestStep {
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

        func adjust(_ item: GlobalDisclosureRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapGlobalDisclosureRequestAdjuster: GlobalDisclosureRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalDisclosureRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredGlobalDisclosureRequestAdjuster: GlobalDisclosureRequestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalDisclosureRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingGlobalDisclosureRequestAdjuster: GlobalDisclosureRequestStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalDisclosureRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumGlobalDisclosureRequestAdjuster: GlobalDisclosureRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalDisclosureRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global disclosure request steps in order and keeps a trace of each.
    final class GlobalDisclosureRequestEngine {
        var steps: [any GlobalDisclosureRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalDisclosureRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GlobalDisclosureRequest) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalDisclosureRequestStep = steps[index]
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

        func evaluateAll(_ items: [GlobalDisclosureRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGlobalDisclosureRequestEngine(_ flags: Kit.Flags.Registry) -> GlobalDisclosureRequestEngine {
        return GlobalDisclosureRequestEngine(
            steps: [
                FlaggedGlobalDisclosureRequestAdjuster(
                    flags: flags,
                    flag: "global-disclosure-request-pending",
                    percent: 6.8
                ),
                CapGlobalDisclosureRequestAdjuster(cap: 41046.0),
                TieredGlobalDisclosureRequestAdjuster(bounds: [2649.0, 3401.0], rates: [0.95, 1.14]),
                RoundingGlobalDisclosureRequestAdjuster(step: 0.25),
                MinimumGlobalDisclosureRequestAdjuster(minimum: 47.1),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 97447.3
        )
    }
}
